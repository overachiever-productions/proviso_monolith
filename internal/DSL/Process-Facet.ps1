Set-StrictMode -Version 1.0;

<#

	#Update-TypeData -TypeName Proviso.Processing.FacetProcessingResult -DefaultDisplayPropertySet Facet, ProcessingState, ExecuteConfiguration, AssertionsOutcome, ValidationsFailed;

	Import-Module -Name "D:\Dropbox\Repositories\proviso\proviso.psm1" -DisableNameChecking -Force;
	
	#With "D:\Dropbox\Desktop\S4 - New\SQL-120-01.psd1" | Configure-ServerName -ExecuteRebase -Force;
	With "D:\Dropbox\Desktop\S4 - New\SQL-120-01.psd1" | Validate-FirewallRules;

	$PVContext.LastProcessingResult;

#>

function Process-Facet {
	
	param (
		[Parameter(Mandatory)]
		[string]$FacetName,
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
		[PSCustomObject]$Config,
		[Switch]$ExecuteRebase = $false,
		[Switch]$Force = $false,
		[Switch]$ExecuteConfiguration = $false
	);
	
	begin {
		Limit-ValidProvisoDSL -MethodName "Process-Facet";
		
		$facet = $ProvisoFacetsCatalog.GetFacet($FacetName);
		if ($null -eq $facet) {
			throw "Invalid Facet-Name. [$FacetName] does not exist or has not yet been loaded. If this is a custom Facet, verify that [Import-Facet] has been executed.";
		}
		
		if ($ExecuteRebase) {
			if (-not ($Force)) {
				throw "Invalid -ExecuteRebase inputs. Because Rebase CAN be detrimental, it MUST be accompanied with the -Force [switch] as well.";
			}
		}
		
		$facetProcessingResult = New-Object Proviso.Processing.FacetProcessingResult($facet, $ExecuteConfiguration);
		$Context.SetCurrentFacet($facet, $ExecuteRebase, $ExecuteConfiguration, $facetProcessingResult);
	}
	
	process { 
		# --------------------------------------------------------------------------------------
		# Assertions	
		# --------------------------------------------------------------------------------------
		if ($facet.Assertions.Count -gt 0) {
			
			$facetProcessingResult.StartAssertions();
			$results = @();
			
			$assertionsOutcomes = [Proviso.Enums.AssertionsOutcome]::AllPassed;
			foreach ($assert in $facet.Assertions) {
				$assertionResult = New-Object Proviso.Processing.AssertionResult($assert);
				$results += $assertionResult;
				
				try {				
					[ScriptBlock]$codeBlock = $assert.ScriptBlock;
					$output = & $codeBlock;
					
					if ($null -eq $output) {
						$output = $true;
					}
					
					if ($assert.IsNegated) {
						$output = (!$output);
					}
					
					$assertionResult.Complete($output);
				}
				catch {
					$assertionResult.Complete($_);
				}
				
				if ($assertionResult.Failed) {
					if ($assert.NonFatal) {
						$assertionsOutcomes = [Proviso.Enums.AssertionsOutcome]::Warning;
						$Context.WriteLog("WARNING: Non-Fatal Assertion [$($assert.Name)] Failed. Error Detail: $($assertionResult.GetErrorMessage())", "Important");
					}
					else {
						$facetProcessingResult.EndAssertions([Proviso.Enums.AssertionsOutcome]::HardFailure, $results)
						throw "Assertion $($assert.Name) Failed. Error: $($assertionResult.GetErrorMessage())";
					}
				}
			}
			
			$facetProcessingResult.EndAssertions($assertionsOutcomes, $results)
		}
		
		# --------------------------------------------------------------------------------------
		# Definitions / Testing
		# --------------------------------------------------------------------------------------	
		$facetProcessingResult.StartValidations();
		$validations = @();
		$validationsOutcome = [Proviso.Enums.ValidationsOutcome]::Completed;
		foreach ($definition in $facet.Definitions) {
			
			[ScriptBlock]$expectedBlock = $definition.Expectation;
			if (($null -eq $expectedBlock) -and ($null -ne $definition.Key)) {
				# dynamically CREATE a script-block ... that spits out the config key: 
				$script = "return `$Config.GetValue('$($definition.Key)');";
				$expectedBlock = [scriptblock]::Create($script);
			}
			
			[ScriptBlock]$testBlock = $definition.Test;
			
			$comparison = Compare-ExpectedWithActual -ExpectedBlock $expectedBlock -TestBlock $testBlock;
			
			#Write-Host "Comparison for $($definition.Description): $comparison ";
			
			$validationResult = New-Object Proviso.Processing.ValidationResult($definition, ($comparison.ExpectedResult), ($comparison.ActualResult), ($comparison.Matched));
			$validations += $validationResult;
			
			if ($null -ne $comparison.ExpectedError) {
				$validationError = New-Object Proviso.Processing.ValidationError([Proviso.Enums.ValidationErrorType]::Expected, ($comparison.ExpectedError));
				$validationResult.AddValidationError($validationError);
			}
			if ($null -ne $comparison.ActualError) {
				$validationError = New-Object Proviso.Processing.ValidationError([Proviso.Enums.ValidationErrorType]::Actual, ($comparison.ActualError));
				$validationResult.AddValidationError($validationError);
			}
			if($null -ne $comparison.ComparisonError) {
				$validationError = New-Object Proviso.Processing.ValidationError([Proviso.Enums.ValidationErrorType]::Compare, ($comparison.ComparisonError));
				$validationResult.AddValidationError($validationError);
			}
			
			if ($validationResult.Failed) {
				$validationsOutcome = [Proviso.Enums.ValidationsOutcome]::Failed; # i.e., not the same as "didn't match", but... exception/failure.
			}
		}
		
		$facetProcessingResult.EndValidations($validationsOutcome, $validations);
		
		# --------------------------------------------------------------------------------------
		# Rebase
		# --------------------------------------------------------------------------------------
		if ($ExecuteRebase) {
			
			$facetProcessingResult.StartRebase();
			
			[ScriptBlock]$rebaseBlock = $facet.Rebase.RebaseBlock;
			$rebaseResult = New-Object Proviso.Processing.RebaseResult(($facet.Rebase));
			$rebaseOutcome = [Proviso.Enums.RebaseOutcome]::Success;
			
			try {
				& $rebaseBlock;
				
				$rebaseResult.SetSuccess();
			}
			catch {
				$rebaseResult.SetFailure($_);
				$rebaseOutcome = [Proviso.Enums.RebaseOutcome]::Failure;
			}
			
			$facetProcessingResult.EndRebase($rebaseOutcome, $rebaseResult);
			
			if($facetProcessingResult.RebaseFailed){
				$facetProcessingResult.SetProcessingFailed();
				throw "Rebase Execution Failure: $($rebaseResult.RebaseError). Configuration Processing cannot continue. Terminating.";
			}
			
			if ($Context.RebootRequired) {
				Write-Host "Doh! a reboot is required in/after processing Rebase Functionality. Reason: $($Context.RebootReason)";
			}
		}
	
		# --------------------------------------------------------------------------------------
		# Configuration
		# --------------------------------------------------------------------------------------		
		if ($ExecuteConfiguration) {
			
			if ($facetProcessingResult.ValidationsFailed){
				# vNEXT: might... strangely, also, make sense to let some comparisons/failures be NON-FATAL (but, assume/default to fatal... in all cases)
				$Context.CloseCurrentFacet();
				throw "Unable to process configuration-operations for Facet [$FacetName] - Validations Failed.";
			}
			
			$facetProcessingResult.StartConfigurations();
			$configurations = @();
			$configurationsOutcome = [Proviso.Enums.ConfigurationsOutcome]::Completed;
			
			foreach($validation in $facetProcessingResult.GetValidationResults()) {
				
				$configResult = New-Object Proviso.Processing.ConfigurationResult($validation);
				$configurations += $configResult;
				
				if ($validation.Matched) {
					$configResult.SetBypassed();
					$Context.WriteLog("Bypassing configuration of [$($definition.Description)] - Expected and Actual values already matched.", "Verbose")
				}
				else {
					if ($Context.RebootRequired) {
						# if reboot allowed, spin up a restart operation, log that we're rebooting/restarting and ... restart. 
						# else... throw an exception that we're pending a reboot? (or maybe there's a way to keep going?)
						#   i.e., maybe there needs to be a $Context.RebootPendingBehavior of { Continue | Throw | Reboot | RebootAndRestartFacet }
					}
					else {
						
						try {
							[ScriptBlock]$configureBlock = $validation.Configure;
							
							& $configureBlock;
							$configResult.SetSucceeded();
						}
						catch {
							$configurationsOutcome = [Proviso.Enums.ConfigurationsOutcome]::Failed;
							$configurationError = New-Object Proviso.Processing.ConfigurationError($_, $false);
							$configResult.AddConfigurationError($configurationError);
						}
						
						# Recomparisons:
						if ($configResult.ConfigurationSucceeded) {
							try {
								[ScriptBlock]$expectedBlock = $definition.Expectation;
								[ScriptBlock]$testBlock = $validation.Test;
								
								$reComparison = Compare-ExpectedWithActual -ExpectedBlock $expectedBlock -TestBlock $testBlock;
								
								if ($reComparison.Matched) {
									$configResult.SetRecompareSucceeded(($reComparison.ExpectedResult), ($reComparison.ActualResult), ($reComparison.Matched));
								}
							}
							catch {
								$configurationsOutcome = [Proviso.Enums.ConfigurationsOutcome]::RecompareFailed;
								$configurationError = New-Object Proviso.Processing.ConfigurationError($_, $true);
								$configResult.AddConfigurationError($configurationError);
							}
						}
					}
				}
			}
			
			$facetProcessingResult.EndConfigurations($configurationsOutcome, $configurations);
		}
	}
	
	end {
		$Context.CloseCurrentFacet();
<# 
		
	For Reference, here's what the current output looks like:
		
Facet                 : Proviso.Models.Facet
ExecuteConfiguration  : True
ProcessingStart       : 10/16/2021 4:05:09 PM
ProcessingEnd         :
ProcessingState       : AssertsStarted, AssertsEnded, ValidationsStarted, ValidationsEnded, RebaseStarted, RebaseEnded, ConfigurationsStarted
AssertionsOutcome     : AllPassed
AssertionResults      : {Proviso.Processing.AssertionResult, Proviso.Processing.AssertionResult, Proviso.Processing.AssertionResult}
AssertionsFailed      : False
ValidationsOutcome    : Completed
ValidationResults     : {Proviso.Processing.ValidationResult, Proviso.Processing.ValidationResult}
ValidationsFailed     : False
RebaseOutcome         : Success
RebaseResult          : Proviso.Processing.RebaseResult
RebaseFailed          : False
ConfigurationsOutcome : UnProcessed
ConfigurationResults  : {}
ConfigurationsFailed  : False
		
		
		
	Fodder: 
		- https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_format.ps1xml?view=powershell-7.1
		
		JACKPOT:
		- https://docs.microsoft.com/en-us/powershell/scripting/developer/format/formatting-file-overview?view=powershell-7.1
		
		DETAILED xml format/schema docs:
		- https://docs.microsoft.com/en-us/powershell/scripting/developer/format/format-schema-xml-reference?view=powershell-7.1
		
		
		TODO: 
		Look into the use of 'Property Sets' as outlined near the bottom of this post: 
		- https://mcpmag.com/articles/2014/05/13/powershell-properties-part-3.aspx
		
		
		
		- https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/export-formatdata?view=powershell-7.1
		- https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/update-formatdata?view=powershell-7.1
			-prependPath = OVERWRITE any formatting that might already exist. -appendPath = put formatting defs safely 'at end' of all other defs - i.e., don't overwrite. 
		
		AWESOME:
		- https://stackoverflow.com/questions/67990004/is-there-a-way-to-cause-powershell-to-use-a-particular-format-for-a-functions-o
		
		MIGHT be useful: 
		- https://stackoverflow.com/questions/13611380/safe-use-of-update-formatdata 
		- https://petri.com/using-formatting-files-with-powershell-7
		
		
		
	Example of Expected/Desired formatting for FacetProcessingResult
		1. It'll have the following properties: Facet, ProcessingResults, Assertions, Validations, Configurations
		
		2. And, each of the above can/should look roughly like the following (in order) 
		
FACET 
	Name: <facetName> 
	FileName: <filename>
	[ConfigSection: config key if present]
	AllowsRebase:
		
PROCESSING RESULTS 
	Execution: <start-timestamp> - <end-timestamp>  (total ms)
	Reboot Executed: 
	Reboot Required: 
	Processing States: AssertsStarted, AssertsEnded, ValidationsStarted, ValidationsEnded, etc.... 
	Assertions Outcome: AllPassed, etc. 
	Assertions with Warnings: name1, name2
	Failed Assertions: name1, name2
	Failed Validations: name1, name2, etc. 
	Rebase Executed: true/false (only if a. configure, and b. rebase was present)
	Rebase Outcome: pass/fail (only if possible AND if executed)
	
ASSERTIONS 
	<assertion-name>: Passed | FailedWithWarning | FailedWithException
	<assertion-name>: Passed | FailedWithWarning | FailedWithException
	<assertion-name>: Passed | FailedWithWarning | FailedWithException
	etc... 
		
		
VALIDATIONS 
	Definition					 			Matched		Expectation 			Actual
	------------------------------------	--------	----------------------	--------------------
	IP Address								TRUE		192.168.1.100			10.20.0.200
	etc										FALSE		Y						Y	
	something name here - truncated ... 	EXCEPTION	1234 - 4567				ERROR 1 *
		
		
	VALIDATION ERRORS: 
	1 - error message here. 
	2 - error message here ofr error 2 from above, and so on... 
		
CONFIGURATIONS 
	DEFINITION: <name here>
		Expected: 192.168.1.100
		Actual: 10.20.0.200
		Matched: false
		Processing: <start> - <end> (total MS)
		New-Actual: 192.168.1.100
		New-Matched: true
		Outcome: SUCCESS | FAILURE | ERROR (failure = no error, but didn't match). 
		[Error Detail]
			Type: Expected | Actual | Comparison | Re-Actual | Re-Comparison
			Message: goes here if there was any kind of exception... 
		[Error Detail] (i.e., another one - if present) 
			Type: Expected | Actual | Comparison | Re-Actual | Re-Comparison
			Message: goes here if there was any kind of exception... 
		
	DEFINITION: <name here>		
		Expected: 
		Actual: 
		Matched: true 
		Processing: 0ms 
		Outcome: SKIPPED (already matched) 
		
	DEFINITION: <n...>
#>		
		
	}
}