Set-StrictMode -Version 1.0;

<#

# intermediate dev/testing against target VMs:

	#Register-PSRepository -Name Pro2 -SourceLocation "\\storage\lab\proviso\repo2" -InstallationPolicy Trusted;


Install-Module -Name Proviso -Repository Pro2 -Force;
Import-Module -Name Proviso -Force -DisableNameChecking;
Assign -ProvisoRoot "\\storage\Lab\proviso\";
Target -CurrentHost;
Do-Something;



	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Assign -ProvisoRoot "\\storage\Lab\proviso\";
	Target "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1";

	Configure-TestingSurface;
	Summarize -All; # -IncludeAllValidations; # -IncludeAssertions;

#>

function Process-Surface {
	param (
		[Parameter(Mandatory)]
		[string]$SurfaceName,
		[switch]$Configure = $false,
		[switch]$ExecuteRebase = $false,
		[switch]$Force = $false
	);
	
	begin {
		Validate-Config;
		Validate-MethodUsage -MethodName "Process-Surface";
		
		$surface = $global:PVCatalog.GetSurface($SurfaceName);
		if ($null -eq $surface) {
			throw "Invalid Surface-Name. [$SurfaceName] does not exist or has not yet been loaded. If this is a custom Surface, verify that [Import-Surface] has been executed.";
		}
		
		if ($ExecuteRebase) {
			if (-not ($Force)) {
				throw "Invalid -ExecuteRebase inputs. Because Rebase CAN be detrimental, it MUST be accompanied with the -Force [switch] as well.";
			}
		}
		
		$surfaceProcessingResult = New-Object Proviso.Processing.SurfaceProcessingResult($surface, $Configure);
		$processingGuid = $surfaceProcessingResult.ProcessingId;
		$PVContext.SetCurrentSurface($surface, $ExecuteRebase, $Configure, $surfaceProcessingResult);
	}
	
	process {
		# --------------------------------------------------------------------------------------
		# Setup	
		# --------------------------------------------------------------------------------------
		if ($surface.Setup.SetupBlock) {
			try {
				[ScriptBlock]$setupBlock = $surface.Setup.SetupBlock;
				
				& $setupBlock;
			}
			catch{
				$PVContext.WriteLog("FATAL: Surface.Setup FAILED for Surface [$($surface.Name)]. Error Detail: $($_)", "Critical");
			}
		}
		
		# --------------------------------------------------------------------------------------
		# Assertions	
		# --------------------------------------------------------------------------------------
		$assertionsFailed = $false;
		if ($surface.Assertions.Count -gt 0) {
			
			$surfaceProcessingResult.StartAssertions();
			$results = @();
			
			$assertionsOutcomes = [Proviso.Enums.AssertionsOutcome]::AllPassed;
			foreach ($assert in $surface.Assertions) {
				$assertionResult = New-Object Proviso.Processing.AssertionResult($assert, $processingGuid);
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
						$PVContext.WriteLog("WARNING: Non-Fatal Assertion [$($assert.Name)] Failed. Error Detail: $($assertionResult.GetErrorMessage())", "Important");
					}
					else {
						$assertionsFailed = $true;
						$PVContext.WriteLog("FATAL: Assertion [$($assert.Name)] Failed. Error Detail: $($assertionResult.GetErrorMessage())", "Critical");
					}
				}
			}
			
			if ($assertionsFailed) {
				$surfaceProcessingResult.EndAssertions([Proviso.Enums.AssertionsOutcome]::HardFailure, $results);
				
				$surfaceProcessingResult.SetProcessingComplete();
				$PVContext.CloseCurrentSurface();
				
				return; 
			}
			else {
				$surfaceProcessingResult.EndAssertions($assertionsOutcomes, $results);
			}
		}
		
		# --------------------------------------------------------------------------------------
		# Validations
		# --------------------------------------------------------------------------------------	
		$validations = @();
		$surfaceProcessingResult.StartValidations();
		$validationsOutcome = [Proviso.Enums.ValidationsOutcome]::Completed;
		
		$facets = $surface.GetSimpleFacets();
		$valueFacets = $surface.GetBaseValueFacets();
		$groupFacets = $surface.GetBaseGroupFacets();
		$compoundFacets = $surface.GetBaseCompoundFacets();
		
		if ($valueFacets) {
			$expandedFacets = @();
			
			foreach ($facets in $valueFacets) {
				
				$values = $PVConfig.GetValue($facet.IterationKey);
				if ($values.Count -lt 1) {
					$PVContext.WriteLog("NOTE: No Config Array-Values were found at key [$($facet.IterationKey)] for Facet [$($facet.Parent.Name)::$($facet.Description)].", "Important");
				}
				
				# TODO: add in OrderBy functionality (ascending (by default) or descending if/when switch is set... )
				foreach ($value in $values) {
					$newDescription = "$($facet.Description):$($value)";
					
					$expandedValueFacet = New-Object Proviso.Models.Facet(($facet.Parent), $newDescription, [Proviso.Enums.FacetType]::Value);
					$expandedValueFacet.SetTest(($facet.Test));
					$expandedValueFacet.SetConfigure(($facet.ConfiguredBy), ($facet.UsesBuild));
					
					if ($facet.ExpectCurrentIterationKey) {
						$script = "return '$value';";
						$expectedBlock = [scriptblock]::Create($script);
						
						$expandedValueFacet.SetExpect($expectedBlock);
					}
					else {
						$expandedValueFacet.SetExpect(($facet.Expect));
					}
					
					$expandedValueFacet.SetCurrentIteratorDetails($facet.IterationKey, $value);
					$expandedDefs += $expandedValueFacet;
				}
			}
			
			$facets += $expandedFacets;
		}
		
		if ($groupFacets) {
			$expandedFacets = @();
			
			foreach ($facet in $groupFacets) {
				
				[string]$trimmedKey = ($facet.IterationKey) -replace ".\*", "";
	
				$groupNames = Get-ProvisoConfigGroupNames -Config $PVConfig -GroupKey $trimmedKey -OrderByKey:$($facet.OrderByChildKey);
				if ($groupNames.Count -lt 1) {
					$PVContext.WriteLog("NOTE: No Configuration Group-Values were found at key [$($facet.IterationKey)] for Facet [$($facet.Parent.Name)::$($facet.Description)].", "Important");
				}
				
				foreach ($groupName in $groupNames) {
					$newDescription = "$($facet.Description):$($groupName)";
					$expandedGroupFacet = New-Object Proviso.Models.Facet(($facet.Parent), $newDescription, [Proviso.Enums.FacetType]::Group);
					
					$expandedGroupFacet.SetTest(($facet.Test));
					$expandedGroupFacet.SetConfigure(($facet.Configure), ($facet.UsesBuild));
					
					$currentIteratorKey = "$($trimmedKey).$($groupName)";
					$currentIteratorKeyValue = $groupName;
					
					$currentIteratorChildKey = $null;
					$currentIteratorChildKeyValue = $null;
					
					if ($facet.ExpectCurrentIterationKey) {
						$script = "return '$currentIteratorKeyValue';";
						$expectedBlock = [scriptblock]::Create($script);
						
						$expandedGroupFacet.SetExpect($expectedBlock);
					}
					else {
						if ($facet.ExpectGroupChildKey) {
							
							$currentIteratorChildKey = "$($trimmedKey).$($groupName).$($facet.ChildKey)";
							$currentIteratorChildKeyValue = $PVConfig.GetValue($currentIteratorChildKey);
									
							$script = "return '$currentIteratorChildKeyValue';";
							$expectedBlock = [scriptblock]::Create($script);
							
							$expandedGroupFacet.SetExpect($expectedBlock);
						}
						else {
							# then it's 'just' a normal expect: 
							$expandedGroupFacet.SetExpect(($facet.Expect));
						}
					}
					
					$expandedGroupFacet.SetCurrentIteratorDetails($currentIteratorKey, $currentIteratorKeyValue, $currentIteratorChildKey, $currentIteratorChildKeyValue);
					
					$expandedFacets += $expandedGroupFacet;
				}
			}
			
			$facets += $expandedFacets;
		}
		
		if ($compoundFacets) {
			$expandedFacets = @();
			
			foreach ($facet in $compoundFacets){
				[string]$trimmedKey = ($facet.IterationKey) -replace ".\*", "";
				$groupNames = Get-ProvisoConfigGroupNames -Config $PVConfig -GroupKey $trimmedKey -OrderByKey:$($facet.OrderByChildKey);
				if ($groupNames.Count -lt 1) {
					$PVContext.WriteLog("NOTE: No Configuration Group-Values were found at key [$($facet.IterationKey)] for Facet [$($facet.Parent.Name)::$($facet.Description)].", "Important");
				}
				
				foreach ($groupName in $groupNames){
					$fullCompoundKey = "$trimmedKey.$groupName.$($facet.CompoundIterationKey)";
					# TODO: implement the .OrderDescending logic in this helper func... 
					$compoundChildElements = Get-ProvisoConfigCompoundValues -Config $PVConfig -FullCompoundKey $fullCompoundKey -OrderDescending:$($facet.OrderDescending);
					
					if ($compoundChildElements.Count -lt 1){
						$PVContext.WriteLog("NOTE: No COMPOUND Keys were found at key [$fullCompoundKey] for Facet [$($facet.Parent.Name)::$($facet.Description)].", "Important");
					}
					else{
						foreach ($compoundValue in $compoundChildElements){
							$compoundDescription = "$($facet.Description):$($groupName).$compoundValue";
							
							$compoundFacet = New-Object Proviso.Models.Facet(($facet.Parent), $compoundDescription, [Proviso.Enums.FacetType]::Compound);
							$compoundFacet.SetTest($facet.Test);
							$compoundFacet.SetConfigure(($facet.Configure), ($facet.UsesBuild));
							
							$iteratorKey = "$($trimmedKey).$($groupName)";
							$iteratorValue = $groupName;
							
							$iteratorChildKey = $fullCompoundKey;
							$iteratorChildKeyValue = $compoundValue;
							
							if ($facet.ExpectCurrentIterationKey){
								$script = "return '$iteratorValue';";
								$expectedBlock = [scriptblock]::Create($script);
								
								$compoundFacet.SetExpect($expectedBlock);
							}
							else {
								if ($facet.ExpectCompoundValueKey) {
									$script = "return '$iteratorChildKeyValue';";
									$expectedBlock = [scriptblock]::Create($script);
									
									$compoundFacet.SetExpect($expectedBlock);
								}
								else {
									$compoundFacet.SetExpect(($facet.Expect));
								}
							}
							
							$compoundFacet.SetCurrentIteratorDetails($iteratorKey, $iteratorValue, $iteratorChildKey, $iteratorChildKeyValue);
							$expandedFacets += $compoundFacet;
						}
					}
				}
			}
			
			$facets += $expandedFacets;
		}
		
		foreach ($facet in $facets) {
			$validationResult = New-Object Proviso.Processing.ValidationResult($facet, $processingGuid); 
			$validations += $validationResult;
			
			[ScriptBlock]$expectedBlock = $facet.Expect;
			if ($null -eq $expectedBlock) {
				if ($facet.ExpectStaticKey) {
					$script = "return `$PVConfig.GetValue('$($facet.Key)');";
					$expectedBlock = [scriptblock]::Create($script);
				}
				else {
					throw "Proviso Framework Error. Expect block should be loaded (via various options) - but is NOT.";	
				}
			}
			
			$expectedResult = $null;
			$expectedException = $null;
			
			$PVContext.SetValidationState($facet);
			
			try {
				$expectedResult = & $expectedBlock;
			}
			catch {
				$expectedException = $_;
			}
						
			if ($expectedException) {
				$validationError = New-Object Proviso.Processing.ValidationError([Proviso.Enums.ValidationErrorType]::Expected, $expectedException);
				$validationResult.AddValidationError($validationError);
			}
			else {
				$PVContext.SetCurrentExpectValue($expectedResult);
				$validationResult.AddExpectedResult($expectedResult);
				
				[ScriptBlock]$testBlock = $facet.Test;
				
				$comparison = Compare-ExpectedWithActual -Expected $expectedResult -TestBlock $testBlock;
				
				$validationResult.AddComparisonResults(($comparison.ActualResult), ($comparison.Matched));
				
				if ($null -ne $comparison.ActualError) {
					$validationError = New-Object Proviso.Processing.ValidationError([Proviso.Enums.ValidationErrorType]::Actual, ($comparison.ActualError));
					$validationResult.AddValidationError($validationError);
				}
				
				if ($null -ne $comparison.ComparisonError) {
					$validationError = New-Object Proviso.Processing.ValidationError([Proviso.Enums.ValidationErrorType]::Compare, ($comparison.ComparisonError));
					$validationResult.AddValidationError($validationError);
				}
				
				if ($validationResult.Failed) {
					$validationsOutcome = [Proviso.Enums.ValidationsOutcome]::Failed; # i.e., exception/failure.
				}
			}
			
			$PVContext.ClearCurrentState();
		}
		
		$surfaceProcessingResult.EndValidations($validationsOutcome, $validations);
		
		# --------------------------------------------------------------------------------------
		# Rebase
		# --------------------------------------------------------------------------------------
		if ($ExecuteRebase) {
			
			$surfaceProcessingResult.StartRebase();
			
			if ($surfaceProcessingResult.ValidationsFailed) {
				$PVContext.WriteLog("FATAL: Rebase Failure - One or more Validations threw an exception (and could not be properly evaluated). Rebase Processing can NOT continue. Terminating.", "Critical");
				$surfaceProcessingResult.EndRebase([Proviso.Enums.RebaseOutcome]::Failure, $null);
				
				$surfaceProcessingResult.SetProcessingComplete();
				$PVContext.CloseCurrentSurface();
				
				return;
			}
			
			[ScriptBlock]$rebaseBlock = $surface.Rebase.RebaseBlock;
			$rebaseResult = New-Object Proviso.Processing.RebaseResult(($surface.Rebase), $processingGuid);
			$rebaseOutcome = [Proviso.Enums.RebaseOutcome]::Success;
			
			try {
				& $rebaseBlock;
				
				$rebaseResult.SetSuccess();
			}
			catch {
				$rebaseResult.SetFailure($_);
				$rebaseOutcome = [Proviso.Enums.RebaseOutcome]::Failure;
			}
			
			$surfaceProcessingResult.EndRebase($rebaseOutcome, $rebaseResult);
			
			if($surfaceProcessingResult.RebaseFailed){
				$surfaceProcessingResult.SetProcessingFailed();
				$PVContext.WriteLog("FATAL: Rebase Failure: [$($rebaseResult.RebaseError)].  Configuration Processing can NOT continue. Terminating.", "Critical");
				
				$surfaceProcessingResult.SetProcessingComplete();
				$PVContext.CloseCurrentSurface();
				
				return;
			}
		}
	
		# --------------------------------------------------------------------------------------
		# Configuration
		# --------------------------------------------------------------------------------------		
		if ($Configure) {
			
			$surfaceProcessingResult.StartConfigurations();
			
			if ($surfaceProcessingResult.ValidationsFailed){
				# vNEXT: might... strangely, also, make sense to let some comparisons/failures be NON-FATAL (but, assume/default to fatal... in all cases)
				$PVContext.WriteLog("FATAL: Configurations Failure - One or more Validations threw an exception (and could not be properly evaluated). Configuration Processing can NOT continue. Terminating.", "Critical");
				$surfaceProcessingResult.EndConfigurations([Proviso.Enums.ConfigurationsOutcome]::Failed, $null);
				
				$surfaceProcessingResult.SetProcessingComplete();
				$PVContext.CloseCurrentSurface();
				
				return;
			}
			
			$configurations = @();
			$configurationsOutcome = [Proviso.Enums.ConfigurationsOutcome]::Completed;
			
			[string[]]$configuredByFacetsCalledThroughDeferredOperations = @();
			
			foreach($validation in $surfaceProcessingResult.ValidationResults) {
							
				$configurationResult = New-Object Proviso.Processing.ConfigurationResult($validation);
				$configurations += $configurationResult;
				
				if ($validation.Matched) {
					$configurationResult.SetBypassed();
					$PVContext.WriteLog("Bypassing configuration of [$($validation.Description)] - Expected: [$($validation.Expected)] and Actual: [$($validation.Actual)] values already matched.", "Debug");
				}
				else {
					$PVContext.SetConfigurationState($validation);
					
					try {
						[ScriptBlock]$configureBlock = $null;
						if ($validation.ParentFacet.UsesBuild) {
							$configureBlock = $surface.Build.BuildBlock;
						}
						else {
							$configureBlock = $validation.Configure;
						}
						
						& $configureBlock;
					}
					catch {
						$configurationsOutcome = [Proviso.Enums.ConfigurationsOutcome]::Failed;
						$configurationError = New-Object Proviso.Processing.ConfigurationError($_);
						$configurationResult.AddConfigurationError($configurationError);
					}
					
					$PVContext.ClearCurrentState();
				}
			}
			
			if ($surface.UsesBuild) {
				# NOTE: there's no 'state' within a Deploy operation... (e.g., Configure operations use .SetConfigurationState(), validations use .SetValidationState(), but ... there's NO state here.)
				try {
					[ScriptBlock]$deployBlock = $surface.Deploy.DeployBlock;
					
					& $deployBlock;
				}
				catch {
					# TODO: MIGHT want to create a specific type of error: Deploy Error... 
					$configurationsOutcome = [Proviso.Enums.ConfigurationsOutcome]::Failed;
					$configurationError = New-Object Proviso.Processing.ConfigurationError($_);
					$configurationResult.AddConfigurationError($configurationError);
				}
			}
			
			# Now that we're done running configuration operations, time to execute Re-Compare operations:
			$targets = $configurations | Where-Object { ($_.ConfigurationBypassed -eq $false) -and ($_.ConfigurationFailed -eq $false);	};
			foreach ($configurationResult in $targets) {
				$PVContext.SetConfigurationState($configurationResult.Validation);
				$PVContext.SetRecompareActive();
				
				try {
					[ScriptBlock]$testBlock = $configurationResult.Validation.Test;
					
					$reComparison = Compare-ExpectedWithActual -Expected ($configurationResult.Validation.Expected) -TestBlock $testBlock;
					
					$configurationResult.SetRecompareValues(($configurationResult.Validation.Expected), ($reComparison.ActualResult), ($reComparison.Matched), ($reComparison.ActualError), ($reComparison.ComparisonError));
				}
				catch {
					$configurationError = New-Object Proviso.Processing.ConfigurationError($_);
					$configurationResult.AddConfigurationError($configurationError);
				}
				
				if ($configurationResult.RecompareFailed) {
					$configurationsOutcome = [Proviso.Enums.ConfigurationsOutcome]::RecompareFailed;
				}
				
				$PVContext.SetRecompareInactive();
				$PVContext.ClearCurrentState();
			}
			
			$surfaceProcessingResult.EndConfigurations($configurationsOutcome, $configurations);
		}
	}
	
	end {
		$surfaceProcessingResult.SetProcessingComplete();
		$PVContext.CloseCurrentSurface();
		
		if ($PVContext.RebootRequired) {
			$message = "REBOOT REQUIRED. $($PVContext.RebootReason)";
			
			$PVContext.WriteLog($message, "CRITICAL");
		}
	}
}