Set-StrictMode -Version 1.0;

<#
	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -Force;
	
	With "\\storage\Lab\proviso\definitions\servers\S4\SQL-120-01.psd1" | Validate-ServerName;

#>


function Process-Facet {
	
	param (
		[Parameter(Mandatory)]
		[string]$FacetName,
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
		[PSCustomObject]$Config,
		[switch]$Validate = $false,
		[switch]$Configure = $false,
		[switch]$AllowHardReset = $false
	);
	
	begin {
		if ($Validate -and $Configure) {
			# vNEXT: re-evaluate this. There's no real reason it can't be both. In which case I'd create a new surrogate function called <VerbSomething-ThatMeansValidateAndConfigure>-<FacetName>
			throw "Switches -Validate and -Configure cannot both be set to true. Execute one option or the other.";
		}
		
		# optional: start a stopwatch? 
		
		$facetManager = Get-ProvisoFacetManager;
		$facet = $facetManager.GetFacet($FacetName);
		if ($null -eq $facet) {
			throw "Invalid Facet-Name. [$FacetName] does not exist or has not yet been loaded. If this is a custom Facet, verify Import-Facet has been executed.";
		}
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
						# TODO: write to the proviso log instead of host... 
						#Write-ProvisoLog ...
						Write-Host "WARNING: Non-Fatal Assertion $($assert.Name) Failed. $($assert.AssertionError);";
					}
					else {
						# TODO: build a full-blown object here... along with a view and everything... 
						throw "Assertion $($assert.Name) Failed. Error: $($assert.AssertionError)";
					}
				}
				else {
					
				}
			}
		}
		
		
		# --------------------------------------------------------------------------------------
		# Assertions	
		# --------------------------------------------------------------------------------------		
		
		# --------------------------------------------------------------------------------------
		#  Execute Definition Tests. 
		#  foreach Definition: 
		# 		try/catch + keep going on any exceptions (want to test ALL expectations)
		# 		get expectation + test 
		# 			some expectations may be scalar (actually, scalar expectations will be turned into [ScriptBlock]$expectation = { $scalarValueHere;} inside of Facet.Definition itself...  )
		# 		  run the test. 
		# 		  save the result (exception or output) as a C# TestOutcome. 
		# 
		#
		
		if ($Validate) {
			
			foreach ($definition in $facet.Definitions){
				
				# test-runner type object (that compares inputs and outputs... )
				#$tester = New-Object Proviso.Models.TestEvaluator();
				
				[ScriptBlock]$expectedBlock = $definition.Expectation;
				$expectedOutcome = & $expectedBlock;
				Write-Host "Outcome of Expectation for $($definition.Description) was: $expectedOutcome";
				
				[ScriptBlock]$testBlock = $definition.Test;
				$testOutcome = & $testBlock;
				Write-Host "Test Outcome for $($definition.Description) was: $testOutcome ";
				
			}
			
			
			# IMPORTANT: don't 'implement' the  following view. 
			# 		instead, make sure that an OBJECT or set of objects is passed out with ALL details ... 
			# 			with the IDEA that if/when -Validate is run... that... end-users will see SOMETHING like the below
			# 					(only, with it as an OBJECT(s) - they can then do stuff against it as desired.
			
			# report on Test-Outcomes - as in: 
			#  		Definition					 	Outcome		Expectation 			Actual
			# 		----------------------------	--------	----------------------	--------------------
			#  		IP Address						FAIL		192.168.1.100			10.20.0.200
			# 		etc								PASS		Y						Y
			
		}
		
		if ($Configure) {
			
			Write-Host "Configuring vs Validating... ";
			
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
		# if stopwatch started, end it and report on timing.
	}
}