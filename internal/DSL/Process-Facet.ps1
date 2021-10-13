Set-StrictMode -Version 1.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\proviso.psm1" -DisableNameChecking -Force;
	
	With "D:\Dropbox\Desktop\S4 - New\SQL-120-01.psd1" | Validate-ServerName; # -ExecuteRebase -Force;
	
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
			[ScriptBlock]$testBlock = $definition.Test;
			
			# vNEXT: allow for ... Expectation to be a value or a block. and if it's a value (not a block) send it into Compare-ExpectedWithActual as -ExpectedValue.
			#  and... address this 'down' in the re-comparison section for config operations as well... 
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
		
		#region output description
		# 
		
		
		
		
		#   here's a ROUGH overview of all of what outputs there can be.... 
		# 		.Facet
		# 			Name: <facet name here> 
		# 			FileName: <filename> 
		# 			RebasePresent: true/false
		# 
		# 		.ProcessingDetails 
		# 			Run: start-timestamp - end-timestamp (xxx milliseconds).
		# 			Reboot Incurred: true/false 
		# 			ProcessingStates: enum showing all states... 
		#			AssertionsOutcome: AllPassed | Warnings | Fatal/Failed - 
		# 			WarnedAssertions: name1, name2. 
		# 			FailedAssertsions: name1, name2, etc. 
		#		  & on... i..e, this can/will get a bit ugly... so, i need to spend some time refactoring and trying to streamline quite a bit. 
		#
		#
		#       .AssertionResults 
		# 			Hmmmm: I could throw these out here... 
		# 			Actually, yeah, that makes a lot of sense. 
		# 			
		# 		.ValidationResults 
		# 			which needs to be a set of OBJECTS that lets me represent something along the lines of the following: 
		# 				i.e., don't output the following, just allow the following via the OBJECTS. 
		#
		#  						Definition					 	Matched		Expectation 			Actual
		# 						----------------------------	--------	----------------------	--------------------
		#  						IP Address						TRUE		192.168.1.100			10.20.0.200
		# 						etc								FALSE		Y						Y		
		#
		#   	.ConfigurationResults 
		# 			if this was a -Configure ... then, i want to be able to show/express roughly the following via OBJECTS: 
		# 			
		# 						<DEFINITION-NAME-HERE>
		# 							Expected: 192.168.1.100
		# 							Actual: 10.20.0.200
		# 							'Outcome': FAIL   	(this name sucks... )
		# 							Configuration-Start: timestamp
		# 							Configuration-Outcome: SUCCESS | FAIL | EXCEPTION  (fail = no exception but the value isn't as expected... )
		# 							Exception: (if there is one.)
		# 							Change-Script: not actually visible in the 'default view..' but definitely part of the object/output.
		#
		# 						<DEFINITION2-NAME-HERE>
		# 							Expected: 192.168.1.100
		# 							Actual: 10.20.0.200
		# 							'Outcome': FAIL   	(this name sucks... )
		# 							Configuration-Start: timestamp
		# 							Configuration-Outcome: SUCCESS | FAIL | EXCEPTION  (fail = no exception but the value isn't as expected... )
		# 							Exception: (if there is one.)
		# 							Change-Script: not actually visible in the 'default view..' but definitely part of the object/output.		
		
		#endregion
		
		$Context.CloseCurrentFacet();
	}
}