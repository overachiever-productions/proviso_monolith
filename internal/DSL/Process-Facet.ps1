Set-StrictMode -Version 1.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	
	With "D:\Dropbox\Desktop\S4 - New\SQL-120-01.psd1" | Validate-FirewallRules;
	#With "D:\Dropbox\Desktop\S4 - New\SQL-120-01.psd1" | Configure-ServerName; # -ExecuteRebase -Force;

	$PVContext.LastProcessingResult;

	Summarize -All; # -IncludeAssertions;

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
		$assertionsFailed = $false;
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
						$output = (-not $output);
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
						$assertionsFailed = $true;
						$Context.WriteLog("FATAL: Assertion [$($assert.Name)] Failed. Error Detail: $($assertionResult.GetErrorMessage())", "Critical");
					}
				}
			}
			
			if ($assertionsFailed) {
				$facetProcessingResult.EndAssertions([Proviso.Enums.AssertionsOutcome]::HardFailure, $results);
				
				$facetProcessingResult.SetProcessingComplete();
				$Context.CloseCurrentFacet();
				
				return; 
			}
			else {
				$facetProcessingResult.EndAssertions($assertionsOutcomes, $results);
			}
		}
		
		# --------------------------------------------------------------------------------------
		# Definitions / Testing
		# --------------------------------------------------------------------------------------	
		$validations = @();
		$facetProcessingResult.StartValidations();
		$validationsOutcome = [Proviso.Enums.ValidationsOutcome]::Completed;
		foreach ($definition in $facet.Definitions) {
			
			[ScriptBlock]$expectedBlock = $definition.Expectation;
			if (($null -eq $expectedBlock) -and ($null -ne $definition.Key)) { 	# dynamically CREATE a script-block ... that spits out the config key: 
				$script = "return `$Config.GetValue('$($definition.Key)');";
				$expectedBlock = [scriptblock]::Create($script);
			}
			
			[ScriptBlock]$testBlock = $definition.Test;
			
			$comparison = Compare-ExpectedWithActual -ExpectedBlock $expectedBlock -TestBlock $testBlock;
			
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
				$validationsOutcome = [Proviso.Enums.ValidationsOutcome]::Failed; # i.e., exception/failure.
			}
		}
		
		$facetProcessingResult.EndValidations($validationsOutcome, $validations);
		
		# --------------------------------------------------------------------------------------
		# Rebase
		# --------------------------------------------------------------------------------------
		if ($ExecuteRebase) {
			
			$facetProcessingResult.StartRebase();
			
			if ($facetProcessingResult.ValidationsFailed) {
				$Context.WriteLog("FATAL: Rebase Failure - One or more Validations threw an exception (and could not be properly evaluated). Rebase Processing can NOT continue. Terminating.", "Critical");
				$facetProcessingResult.EndRebase([Proviso.Enums.RebaseOutcome]::Failure, $null);
				
				$facetProcessingResult.SetProcessingComplete();
				$Context.CloseCurrentFacet();
				
				return;
			}
			
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
				$Context.WriteLog("FATAL: Rebase Failure: [$($rebaseResult.RebaseError)].  Configuration Processing can NOT continue. Terminating.", "Critical");
				
				$facetProcessingResult.SetProcessingComplete();
				$Context.CloseCurrentFacet();
				
				return;
			}
		}
	
		# --------------------------------------------------------------------------------------
		# Configuration
		# --------------------------------------------------------------------------------------		
		if ($ExecuteConfiguration) {
			
			$facetProcessingResult.StartConfigurations();
			
			if ($facetProcessingResult.ValidationsFailed){
				# vNEXT: might... strangely, also, make sense to let some comparisons/failures be NON-FATAL (but, assume/default to fatal... in all cases)
				$Context.WriteLog("FATAL: Configurations Failure - One or more Validations threw an exception (and could not be properly evaluated). Configuration Processing can NOT continue. Terminating.", "Critical");
				$facetProcessingResult.EndConfigurations([Proviso.Enums.ConfigurationsOutcome]::Failed, $null);
				
				$facetProcessingResult.SetProcessingComplete();
				$Context.CloseCurrentFacet();
				
				return;
			}
			
			$configurations = @();
			$configurationsOutcome = [Proviso.Enums.ConfigurationsOutcome]::Completed;
			
			foreach($validation in $facetProcessingResult.ValidationResults) {
				
				$configurationResult = New-Object Proviso.Processing.ConfigurationResult($validation);
				$configurations += $configurationResult;
				
				if ($validation.Matched) {
					$configurationResult.SetBypassed();
					$Context.WriteLog("Bypassing configuration of [$($definition.Description)] - Expected and Actual values already matched.", "Debug");
				}
				else {
					
					try {
						[ScriptBlock]$configureBlock = $validation.Configure;
						
						& $configureBlock;
						
						$configurationResult.SetConfigurationSucceeded();
					}
					catch {
						$configurationsOutcome = [Proviso.Enums.ConfigurationsOutcome]::Failed;
						$configurationError = New-Object Proviso.Processing.ConfigurationError($_, $false);
						$configurationResult.AddConfigurationError($configurationError);
					}
					
					# Recomparisons:
					if ($configurationResult.ConfigurationSucceeded) {
						try {
							[ScriptBlock]$expectedBlock = $definition.Expectation;
							[ScriptBlock]$testBlock = $validation.Test;
							
							$reComparison = Compare-ExpectedWithActual -ExpectedBlock $expectedBlock -TestBlock $testBlock;
							
							$configurationResult.SetRecompareCompleted(($reComparison.ExpectedResult), ($reComparison.ActualResult), ($reComparison.Matched));
						}
						catch {
							$configurationsOutcome = [Proviso.Enums.ConfigurationsOutcome]::RecompareFailed;
							$configurationError = New-Object Proviso.Processing.ConfigurationError($_, $true);
							$configurationResult.AddConfigurationError($configurationError);
						}
					}
				}
			}
			
			$facetProcessingResult.EndConfigurations($configurationsOutcome, $configurations);
		}
	}
	
	end {
		$facetProcessingResult.SetProcessingComplete();
		$Context.CloseCurrentFacet();
	}
}