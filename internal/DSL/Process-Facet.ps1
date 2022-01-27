Set-StrictMode -Version 1.0;

<#

# intermediate dev/testing against target VMs:
	#Register-PSRepository -Name Pro2 -SourceLocation "\\storage\lab\proviso\repo2" -InstallationPolicy Trusted;
Install-Module -Name Proviso -Repository Pro2 -Force;
Import-Module -Name Proviso -Force -DisableNameChecking;
Assign -ProvisoRoot "\\storage\Lab\proviso\";
With -CurrentHost | Do-Something;

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	#Assign -ProvisoRoot "\\storage\Lab\proviso\";

	#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-NetworkAdapters;
	#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-ServerName;	
	#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-FirewallRules;
	#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-RequiredPackages;
	#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-HostTls;

	#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-LocalAdmins;
	#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-TestingFacet;
	With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Provision-TestingFacet;
	#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-DataCollectorSets;

	Summarize -All; # -IncludeAllValidations; # -IncludeAssertions;

#>

function Process-Facet {
	
	param (
		[Parameter(Mandatory)]
		[string]$FacetName,
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
		[PSCustomObject]$Config,
		[switch]$Provision = $false,
		[switch]$ExecuteRebase = $false,
		[switch]$Force = $false
	);
	
	begin {
		Validate-MethodUsage -MethodName "Process-Facet";
		
		$facet = $ProvisoFacetsCatalog.GetFacet($FacetName);
		if ($null -eq $facet) {
			throw "Invalid Facet-Name. [$FacetName] does not exist or has not yet been loaded. If this is a custom Facet, verify that [Import-Facet] has been executed.";
		}
		
		if ($ExecuteRebase) {
			if (-not ($Force)) {
				throw "Invalid -ExecuteRebase inputs. Because Rebase CAN be detrimental, it MUST be accompanied with the -Force [switch] as well.";
			}
		}
		
		$facetProcessingResult = New-Object Proviso.Processing.FacetProcessingResult($facet, $Provision);
		$processingGuid = $facetProcessingResult.ProcessingId;
		$PVContext.SetCurrentFacet($facet, $ExecuteRebase, $Provision, $facetProcessingResult);
	}
	
	process {
		# --------------------------------------------------------------------------------------
		# Setup	
		# --------------------------------------------------------------------------------------
		if ($facet.Setup.SetupBlock) {
			try {
				[ScriptBlock]$setupBlock = $facet.Setup.SetupBlock;
				
				& $setupBlock;
			}
			catch{
				$PVContext.WriteLog("FATAL: Facet.Setup FAILED for Facet [$($facet.Name)]. Error Detail: $($_)", "Critical");
			}
		}
		
		# --------------------------------------------------------------------------------------
		# Assertions	
		# --------------------------------------------------------------------------------------
		$assertionsFailed = $false;
		if ($facet.Assertions.Count -gt 0) {
			
			$facetProcessingResult.StartAssertions();
			$results = @();
			
			$assertionsOutcomes = [Proviso.Enums.AssertionsOutcome]::AllPassed;
			foreach ($assert in $facet.Assertions) {
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
				$facetProcessingResult.EndAssertions([Proviso.Enums.AssertionsOutcome]::HardFailure, $results);
				
				$facetProcessingResult.SetProcessingComplete();
				$PVContext.CloseCurrentFacet();
				
				return; 
			}
			else {
				$facetProcessingResult.EndAssertions($assertionsOutcomes, $results);
			}
		}
		
		# --------------------------------------------------------------------------------------
		# Validations
		# --------------------------------------------------------------------------------------	
		$validations = @();
		$facetProcessingResult.StartValidations();
		$validationsOutcome = [Proviso.Enums.ValidationsOutcome]::Completed;
		
		$definitions = $facet.GetSimpleDefinitions();
		$valueDefs = $facet.GetBaseValueDefinitions();
		$groupDefs = $facet.GetBaseGroupDefinitions();
		$compoundDefs = $facet.GetBaseCompoundDefinitions();
		
		if ($valueDefs) {
			$expandedDefs = @();
			
			foreach ($definition in $valueDefs) {
				
				$values = $PVConfig.GetValue($definition.IterationKey); #Get-ProvisoConfigValueByKey -Config $Config -Key ($definition.IterationKey);
				if ($values.Count -lt 1) {
					$PVContext.WriteLog("NOTE: No Config Array-Values were found at key [$($definition.IterationKey)] for Definition [$($definition.Parent.Name)::$($definition.Description)].", "Important");
				}
				
				# TODO: add in OrderBy functionality (ascending (by default) or descending if/when switch is set... )
				foreach ($value in $values) {
					$newDescription = "$($definition.Description):$($value)";
					
					$expandedValueDefinition = New-Object Proviso.Models.Definition(($definition.Parent), $newDescription, [Proviso.Enums.DefinitionType]::Value);
					
					$expandedValueDefinition.SetTest(($definition.Test));
					
					if ($definition.ConfiguredBy) {
						$configuredByRenamed = "$($definition.ConfiguredBy):$($value)";
						
						$expandedValueDefinition.SetConfigure($newDescription, $configuredByRenamed);
					}
					else{
						$expandedValueDefinition.SetConfigure(($definition.Configure));
					}
					
 					if ($definition.ExpectCurrentIterationKey) {
						$script = "return '$value';";
						$expectedBlock = [scriptblock]::Create($script);
						
						$expandedValueDefinition.SetExpect($expectedBlock);
					}
					else {
						$expandedValueDefinition.SetExpect(($definition.Expect));
					}
					
					$expandedValueDefinition.SetCurrentIteratorDetails($definition.IterationKey, $value);
					$expandedDefs += $expandedValueDefinition;
				}
			}
			
			$definitions += $expandedDefs;
		}
		
		if ($groupDefs) {
			$expandedDefs = @();
			
			foreach ($definition in $groupDefs) {
				
				[string]$trimmedKey = ($definition.IterationKey) -replace ".\*", "";
	
				$groupNames = Get-ProvisoConfigGroupNames -Config $Config -GroupKey $trimmedKey -OrderByKey:$($definition.OrderByChildKey);
				if ($groupNames.Count -lt 1) {
					$PVContext.WriteLog("NOTE: No Configuration Group-Values were found at key [$($definition.IterationKey)] for Definition [$($definition.Parent.Name)::$($definition.Description)].", "Important");
				}
				
				foreach ($groupName in $groupNames) {
					$newDescription = "$($definition.Description):$($groupName)";
					$expandedGroupDefinition = New-Object Proviso.Models.Definition(($definition.Parent), $newDescription, [Proviso.Enums.DefinitionType]::Group);
					
					$expandedGroupDefinition.SetTest(($definition.Test));
					
					if ($definition.ConfiguredBy) {
						$configuredByRenamed = "$($definition.ConfiguredBy):$($groupName)";
						$expandedGroupDefinition.SetConfigure(($definition.Configure), $configuredByRenamed);
					}
					else {
						$expandedGroupDefinition.SetConfigure(($definition.Configure));
					}
					
					$currentIteratorKey = "$($trimmedKey).$($groupName)";
					$currentIteratorKeyValue = $groupName;
					
					$currentIteratorChildKey = $null;
					$currentIteratorChildKeyValue = $null;
					
					if ($definition.ExpectCurrentIterationKey) {
						$script = "return '$currentIteratorKeyValue';";
						$expectedBlock = [scriptblock]::Create($script);
						
						$expandedGroupDefinition.SetExpect($expectedBlock);
					}
					else {
						if ($definition.ExpectGroupChildKey) {
							
							$currentIteratorChildKey = "$($trimmedKey).$($groupName).$($definition.ChildKey)";
							$currentIteratorChildKeyValue = $PVConfig.GetValue($currentIteratorChildKey);
									
							$script = "return '$currentIteratorChildKeyValue';";
							$expectedBlock = [scriptblock]::Create($script);
							
							$expandedGroupDefinition.SetExpect($expectedBlock);
						}
						else {
							# then it's 'just' a normal expect: 
							$expandedGroupDefinition.SetExpect(($definition.Expect));
						}
					}
					
					$expandedGroupDefinition.SetCurrentIteratorDetails($currentIteratorKey, $currentIteratorKeyValue, $currentIteratorChildKey, $currentIteratorChildKeyValue);
					
					$expandedDefs += $expandedGroupDefinition;
				}
			}
			
			$definitions += $expandedDefs;
		}
		
		if ($compoundDefs) {
			$expandedDefs = @();
			
			foreach ($definition in $compoundDefs){
				[string]$trimmedKey = ($definition.IterationKey) -replace ".\*", "";
				$groupNames = Get-ProvisoConfigGroupNames -Config $Config -GroupKey $trimmedKey -OrderByKey:$($definition.OrderByChildKey);
				if ($groupNames.Count -lt 1) {
					$PVContext.WriteLog("NOTE: No Configuration Group-Values were found at key [$($definition.IterationKey)] for Definition [$($definition.Parent.Name)::$($definition.Description)].", "Important");
				}
				
				foreach ($groupName in $groupNames){
					$fullCompoundKey = "$trimmedKey.$groupName.$($definition.CompoundIterationKey)";
					# TODO: implement the .OrderDescending logic in this helper func... 
					$compoundChildElements = Get-ProvisoConfigCompoundValues -Config $Config -FullCompoundKey $fullCompoundKey -OrderDescending:$($definition.OrderDescending);
					
					if ($compoundChildElements.Count -lt 1){
						$PVContext.WriteLog("NOTE: No COMPOUND Keys were found at key [$fullCompoundKey] for Definition [$($definition.Parent.Name)::$($definition.Description)].", "Important");
					}
					else{
						foreach ($compoundValue in $compoundChildElements){
							$compoundDescription = "$($definition.Description):$($groupName).$compoundValue";
							
							$compoundDefinition = New-Object Proviso.Models.Definition(($definition.Parent), $compoundDescription, [Proviso.Enums.DefinitionType]::Compound);
							$compoundDefinition.SetTest($definition.Test);
							
							if ($definition.ConfiguredBy) {
								$compoundNewname = "$($definition.ConfiguredBy):$($groupName).$compoundValue";
								$compoundDefinition.SetConfigure($compoundDescription, $compoundNewname);
							}
							else{
								$compoundDefinition.SetConfigure(($definition.Configure));
							}
							
							$iteratorKey = "$($trimmedKey).$($groupName)";
							$iteratorValue = $groupName;
							
							$iteratorChildKey = $fullCompoundKey;
							$iteratorChildKeyValue = $compoundValue;
							
							if ($definition.ExpectCurrentIterationKey){
								$script = "return '$iteratorValue';";
								$expectedBlock = [scriptblock]::Create($script);
								
								$compoundDefinition.SetExpect($expectedBlock);
							}
							else {
								if ($definition.ExpectCompoundValueKey) {
									$script = "return '$iteratorChildKeyValue';";
									$expectedBlock = [scriptblock]::Create($script);
									
									$compoundDefinition.SetExpect($expectedBlock);
								}
								else {
									$compoundDefinition.SetExpect(($definition.Expect));
								}
							}
							
							$compoundDefinition.SetCurrentIteratorDetails($iteratorKey, $iteratorValue, $iteratorChildKey, $iteratorChildKeyValue);
							$expandedDefs += $compoundDefinition;
						}
					}
				}
			}
			
			$definitions += $expandedDefs;
		}
		
		foreach ($definition in $definitions) {
			$validationResult = New-Object Proviso.Processing.ValidationResult($definition, $processingGuid); 
			$validations += $validationResult;
			
			[ScriptBlock]$expectedBlock = $definition.Expect;
			if ($null -eq $expectedBlock) {
				if ($definition.ExpectStaticKey) {
					$script = "return `$Config.GetValue('$($definition.Key)');";
					$expectedBlock = [scriptblock]::Create($script);
				}
				else {
					throw "Proviso Framework Error. Expect block should be loaded (via various options) - but is NOT.";	
				}
			}
			
			$expectedResult = $null;
			$expectedException = $null;
			
			$PVContext.SetValidationState($definition);
			
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
				
				[ScriptBlock]$testBlock = $definition.Test;
				
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
			
			$PVContext.ClearValidationState();
		}
		
		$facetProcessingResult.EndValidations($validationsOutcome, $validations);
		
		# --------------------------------------------------------------------------------------
		# Rebase
		# --------------------------------------------------------------------------------------
		if ($ExecuteRebase) {
			
			$facetProcessingResult.StartRebase();
			
			if ($facetProcessingResult.ValidationsFailed) {
				$PVContext.WriteLog("FATAL: Rebase Failure - One or more Validations threw an exception (and could not be properly evaluated). Rebase Processing can NOT continue. Terminating.", "Critical");
				$facetProcessingResult.EndRebase([Proviso.Enums.RebaseOutcome]::Failure, $null);
				
				$facetProcessingResult.SetProcessingComplete();
				$PVContext.CloseCurrentFacet();
				
				return;
			}
			
			[ScriptBlock]$rebaseBlock = $facet.Rebase.RebaseBlock;
			$rebaseResult = New-Object Proviso.Processing.RebaseResult(($facet.Rebase), $processingGuid);
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
				$PVContext.WriteLog("FATAL: Rebase Failure: [$($rebaseResult.RebaseError)].  Configuration Processing can NOT continue. Terminating.", "Critical");
				
				$facetProcessingResult.SetProcessingComplete();
				$PVContext.CloseCurrentFacet();
				
				return;
			}
		}
	
		# --------------------------------------------------------------------------------------
		# Provisioning
		# --------------------------------------------------------------------------------------		
		if ($Provision) {
			
			$facetProcessingResult.StartConfigurations();
			
			if ($facetProcessingResult.ValidationsFailed){
				# vNEXT: might... strangely, also, make sense to let some comparisons/failures be NON-FATAL (but, assume/default to fatal... in all cases)
				$PVContext.WriteLog("FATAL: Configurations Failure - One or more Validations threw an exception (and could not be properly evaluated). Configuration Processing can NOT continue. Terminating.", "Critical");
				$facetProcessingResult.EndConfigurations([Proviso.Enums.ConfigurationsOutcome]::Failed, $null);
				
				$facetProcessingResult.SetProcessingComplete();
				$PVContext.CloseCurrentFacet();
				
				return;
			}
			
			$configurations = @();
			$configurationsOutcome = [Proviso.Enums.ConfigurationsOutcome]::Completed;
			
			[string[]]$configuredByDefsCalledThroughDeferredOperations = @();
			
			foreach($validation in $facetProcessingResult.ValidationResults) {
							
				$configurationResult = New-Object Proviso.Processing.ConfigurationResult($validation);
				$configurations += $configurationResult;
				
				if ($validation.Matched) {
					$configurationResult.SetBypassed();
					$PVContext.WriteLog("Bypassing configuration of [$($validation.Description)] - Expected and Actual values already matched.", "Debug");
				}
				elseif ($validation.ParentDefinition.DefersConfiguration) {
					$configurationResult.SetDeferred($validation.ParentDefinition.ConfiguredBy);
							
					if ($configuredByDefsCalledThroughDeferredOperations -notcontains $validation.ParentDefinition.ConfiguredBy) {
						$configuredByDefsCalledThroughDeferredOperations += $validation.ParentDefinition.ConfiguredBy;
					}
					
					$PVContext.WriteLog("Temporarily deferring configuration of [$($validation.Description)] - because Configuration has been deferred to [$($validation.ParentDefinition.ConfiguredBy)].");
				}
				else {
					$PVContext.SetConfigurationState($validation);
					
					try {
						[ScriptBlock]$configureBlock = $validation.Configure;
						
						& $configureBlock;
					}
					catch {
						$configurationsOutcome = [Proviso.Enums.ConfigurationsOutcome]::Failed;
						$configurationError = New-Object Proviso.Processing.ConfigurationError($_);
						$configurationResult.AddConfigurationError($configurationError);
					}
					
					$PVContext.ClearConfigurationState();
				}
			}
			
			# For any Definition that SHOULD have been processed above, but which deferred Configuration/Provisioning operations to its -ConfiguredBy target... process those as needed: 
			foreach ($definitionName in $configuredByDefsCalledThroughDeferredOperations) {
				$validation = $facetProcessingResult.GetValidationResultByDefinitionName($definitionName);
				
				$PVContext.WriteLog("Executing previously deferred Definition [$definitionName] - as it was required for a -ConfiguredBy declaration.", "Debug");
				
				# TODO: this is an EXACT copy/past of the same logic up above... i.e., DRY violation. Guess I might want to move all of this into some 'helper' funcs... 
				# er, well, it was... before i enabled the idea of .IsChildCall().
				$PVContext.SetDeferredExecution();
				$PVContext.SetConfigurationState($validation);
				
				try {
					[ScriptBlock]$configureBlock = $validation.Configure;
					
					& $configureBlock;
				}
				catch {
					$configurationsOutcome = [Proviso.Enums.ConfigurationsOutcome]::Failed;
					$configurationError = New-Object Proviso.Processing.ConfigurationError($_);
					$configurationResult.AddConfigurationError($configurationError);
				}
				
				$PVContext.ClearConfigurationState();
				$PVContext.ClearDeferredExecution();
			}
			
			# Now that we're done running configuration/provisioning operations, time to execute Re-Compare operations:
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
				$PVContext.ClearConfigurationState();
			}
			
			$facetProcessingResult.EndConfigurations($configurationsOutcome, $configurations);
		}
	}
	
	end {
		$facetProcessingResult.SetProcessingComplete();
		$PVContext.CloseCurrentFacet();
		
		if ($PVContext.RebootRequired) {
			$message = "REBOOT REQUIRED. $($PVContext.RebootReason)";
			
			$PVContext.WriteLog($message, "CRITICAL");
		}
	}
}