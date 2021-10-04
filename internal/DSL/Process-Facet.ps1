Set-StrictMode -Version 1.0;

<#
	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	
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
		
		$facet = $ProvisoFacetManager.GetFacet($FacetName);
		if ($null -eq $facet) {
			throw "Invalid Facet-Name. [$FacetName] does not exist or has not yet been loaded. If this is a custom Facet, verify Import-Facet has been executed.";
		}
		$Context.SetCurrentFacet($facet, $ExecuteConfiguration, $AllowHardReset);
	}
	
	process { 
		# --------------------------------------------------------------------------------------
		# Assertions	
		# --------------------------------------------------------------------------------------
		if ($facet.Assertions.Count -gt 0) {
			
			foreach ($assert in $facet.Assertions) {
				
				try {
					$assert.SetAssertionStarted();
					
					[ScriptBlock]$codeBlock = $assert.ScriptBlock;
					& $codeBlock;
					
					$assert.SetAssertionSuccess();
				}
				catch {
					$assert.SetAssertionFailure($_); # https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.ErrorRecord?view=powershellsdk-7.0.0
				}
				
				if ($assert.Failed) {
					if ($assert.NonFatal) {
						$Context.WriteLog("WARNING: Non-Fatal Assertion [$($assert.Name)] Failed. Error Detail: $($assert.AssertionError)", "Important");
					}
					else {
						# TODO: build a full-blown object here... along with a view and everything... 
						throw "Assertion $($assert.Name) Failed. Error: $($assert.AssertionError)";
					}
				}
			}
		}
		
		# --------------------------------------------------------------------------------------
		# Definitions / Testing
		# --------------------------------------------------------------------------------------		
		foreach ($definition in $facet.Definitions) {
			
			[ScriptBlock]$expectedBlock = $definition.Expectation;
			[ScriptBlock]$testBlock = $definition.Test;
			
			#region REFACTOR
			# REFACTOR: push all of the code in this region into the $comparison. 
			#   it'll need to add new properties: .ExpectedResult, .ExpectedException, .ActualResult, .ActualException. 
			# 		and may need a way to differentiate between validation-tests and 're-tests' (i.e., which happen AFTER config blocks are run... )
			#  it'll also need 2x new params: 
			# 		[ScriptBlock]$expectedBlock
			# 		[ScriptBlock]$testBlock
			# 			and... might allow for the option of $expectedBlock to be REPLACED with a scalar value. 
			$expectedResult = $null;
			$expectedException = $null;
			
			try {
				$expectedResult = & $expectedBlock;
			}
			catch {
				$expectedException = $_;
			}
			
			$actualResult = $null;
			$actualException = $null;
			try {
				$actualResult = & $testBlock;
			}
			catch {
				$actualException = $_;
			}
			#endregion
			
			$comparison = Compare-ExpectedWithActual -Expected $expectedResult -Actual $actualResult;
			
			$testOutcome = New-Object Proviso.Models.TestOutcome($expectedResult, $actualResult, ($comparison.Match), ($comparison.Error));
			$definition.SetOutcome($testOutcome);
			
			if ($null -ne ($comparison.Error)){
				$facet.AddDefinitionError($definition, $comparisonError);
			}
		}
		
		if ($ExecuteConfiguration) {
			
			if ($facet.ComparisonsFailed) {
				# vNEXT: get the count and report i.e., "# Validation Comaprison(s) Failed."
				throw "Unable to process configuration-operations for Facet [$FacetName] - Validation Comparisons Failed.";
			}
			
			foreach ($definition in $facet.Definitions) {
				if ($definition.Matched) {
					$Context.Write("Bypassing configuration of [$($definition.Description)] - Expected and Actual values already matched.", "Verbose")
				}
				else {
					if ($Context.RebootRequired) {
						# if reboot allowed, spin up a restart operation, log that we're rebooting/restarting and ... restart. 
						# else... throw an exception that we're pending a reboot? (or maybe there's a way to keep going?)
						#   i.e., maybe there needs to be a $Context.RebootPendingBehavior of { Continue | Throw | Reboot | RebootAndRestartFacet }
					}
					else {
						Write-Host "Processing [$($definition.Description)]::> EXPECTED: $($definition.Outcome.Expected) -> ACTUAL: $($definition.Outcome.Actual) ";
						
						$configurationSucceed = $false;
						try {
							[ScriptBlock]$configureBlock = $definition.Configure;
							
							& $configureBlock;
							
							$reComparison = Compare-ExpectedWithActual 
							
							# re-run the evaluation? I think so actually... 
							#  if so... then wrap the process of testing into a func that returns an object with necessary props (expected, actual, error);
							# 		object can be a simple PSCustomObject... 
							
							# yeah... re-run. and ... $configurationSucceeded ONLY gets set to $true if/when expected and (newActual) actually match. 
							# 	which means... i get to store/keep a .NewActual... or .PostConfigValue, etc. 
						}
						catch {
							
						}
					}
				}
			}
			
			# foreach definition where test-outcome = FAIL (and/or exception?)
			#  		try/catch (and capture any exceptions + try to keep going? hmmm)
			# 			Ah... perfect. Definitions.Config will have a -ExceptionsAsFatal or -ErrorAction thingy that lets each one determine/define if it crashes the whole thing or not. 
			
			# 			otherwise, while we keep going... 
			# 				make the config change - i.e., & $configBlock
			# 			and record the outcome. 
			# 		when we're done, make sure to provide info on pass/fail and such. 
			# 			(as object(s))
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