Set-StrictMode -Version 1.0;

<#
	Import-Module -Name "D:\Dropbox\Repositories\proviso\proviso.psm1" -DisableNameChecking -Force;
	
	With "\\storage\Lab\proviso\definitions\servers\S4\SQL-120-01.psd1" | Configure-ServerName;

#>

function Process-Facet {
	
	param (
		[Parameter(Mandatory)]
		[string]$FacetName,
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
		[PSCustomObject]$Config,
		[switch]$ExecuteConfiguration = $false,
		[switch]$AllowHardReset = $false
	);
	
	begin {
		Limit-ValidProvisoDSL -MethodName "Process-Facet";
		
		$facet = $ProvisoFacetsCatalog.GetFacet($FacetName);
		if ($null -eq $facet) {
			throw "Invalid Facet-Name. [$FacetName] does not exist or has not yet been loaded. If this is a custom Facet, verify that [Import-Facet] has been executed.";
		}
		$facetProcessingResult = New-Object Proviso.Processing.FacetProcessingResult($facet, $ExecuteConfiguration);
		$Context.SetCurrentFacet($facet, $ExecuteConfiguration, $AllowHardReset);
	}
	
	process { 
		# --------------------------------------------------------------------------------------
		# Assertions	
		# --------------------------------------------------------------------------------------
		if ($facet.Assertions.Count -gt 0) {
			
			$facetProcessingResult.StartProcessingAssertions();
			$results = @();
			[bool]$warnings = $false;
			
			foreach ($assert in $facet.Assertions) {
				
				$assertionResult = New-Object Proviso.Processing.AssertionResult($assert);
				$results += $assertionResult;
				
				try {				
					[ScriptBlock]$codeBlock = $assert.ScriptBlock;
					& $codeBlock;
					
					# TODO: I can't JUST run the block ... i have to grab it's outcome. 
					#  i.e., either there's no outcome... which I'll treat as ... true?, or a $false outcome or $true outcome (which I then need to run past -False)
					#    or there's an exception. I'm handling the exception - but not the 'outcome';
					#  and... i should probably pass in a true/false to .Complete as well - i.e., passed/failed - something of that order. 
					#  at which point, $assertionResult.Failed can/will tell whether or not to allow further processing... 
					$assertionResult.Complete();
				}
				catch {
					$assertionResult.Complete($_); 
				}
				
				if ($assert.Failed) {
					if ($assert.NonFatal) {
						$warnings = $true;
						$Context.WriteLog("WARNING: Non-Fatal Assertion [$($assert.Name)] Failed. Error Detail: $($assert.AssertionError)", "Important");
					}
					else {
						$facetProcessingResult.EndProcessingAssertions([Proviso.Enums.AssertionOutcome]::HardFailure, $results)
						throw "Assertion $($assert.Name) Failed. Error: $($assert.AssertionError)";
					}
				}
			}
			
			$outcome = [Proviso.Enums.AssertionsOutcome]::AllPassed;
			if ($warnings) {
				$outcome = [Proviso.Enums.AssertionOutcome]::Warning;
			}
			$facetProcessingResult.EndProcessingAssertions([Proviso.Enums.AssertionsOutcome]::HardFailure, $results)
		}
		
		# --------------------------------------------------------------------------------------
		# Definitions / Testing
		# --------------------------------------------------------------------------------------	
		$facetProcessingResult.StartProcessingValidations();
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
		
		$facetProcessingResult.EndProcessingValidations($validationsOutcome, $validations);
		
		# --------------------------------------------------------------------------------------
		# Rebase
		# --------------------------------------------------------------------------------------
		
		# TODO: ... add in rebase if allowed/etc. 
		
		
		
		# --------------------------------------------------------------------------------------
		# Configuration
		# --------------------------------------------------------------------------------------		
		if ($ExecuteConfiguration) {
			
			if ($facetProcessingResult.ValidationsFailed){
				# vNEXT: get the count and report i.e., "# Validation Comaprison(s) Failed."
				# vNEXT: might... strangely, also, make sense to let some comparisons/failures be NON-FATAL (but, assumde/default to fatal... in all cases)
				$Context.CloseCurrentFacet();
				throw "Unable to process configuration-operations for Facet [$FacetName] - Validation Comparisons Failed.";
			}
			
			$facetProcessingResult.StartProcessingConfiguration();
			$configurations = @();
			$configurationsOutcome = [Proviso.Models.ConfigurationsOutcome]::Completed;
			
			foreach($validation in $facetProcessingResult.GetValidationResults()) {
				
				$configResult = New-Object Proviso.Models.ConfigurationResult($validation);
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
						#Write-Host "Processing [$($validation.Description)]::> EXPECTED: $($validation.Outcome.Expected) -> ACTUAL: $($validation.Outcome.Actual) ";
					
						try {
							[ScriptBlock]$configureBlock = $validation.Configure;
							
							& $configureBlock;
							$configResult.SetSucceeded();
						}
						catch {
							$configurationError = New-Object Proviso.Models.ConfigurationError($_, $false);
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
								$configurationError = New-Object Proviso.Models.ConfigurationError($_, $true);
								$configResult.AddConfigurationError($configurationError);
							}
						}
					}
				}
			}
		}
	}
	
	end {
		# OUTPUT needs to include: 
		# 		.Facet
		# 			so'z the Asserts, Rebase, Defs are all accessible. 
		# 
		# 		.ValidationResults 
		# 			which needs to be a set of OBJECTS that lets me represent something along the lines of the following: 
		# 				i.e., don't output the following, just allow the following via the OBJECTS. 
		#
		#  						Definition					 	Outcome		Expectation 			Actual
		# 						----------------------------	--------	----------------------	--------------------
		#  						IP Address						FAIL		192.168.1.100			10.20.0.200
		# 						etc								PASS		Y						Y		
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
		
		
		
		# ARGUABLY, i can/should be able to GET the $output object from the Facet itself... i.e.,: 
#		$facetOutput = $facet.GetValidationOutput();		# this'll 'know' if there was a configure block or not, and dump all of needed info/summary data from above. 
#		$Context.CloseCurrentFacet($facetOutput);
	}
}