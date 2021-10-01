Set-StrictMode -Version 1.0;

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
		
		#QUESTION: I assume $Config will ... be in scope for all & $block executions? 
		
		Write-Host "Nice. Down, inside of $FacetName, and doing stuff...";
		# Nice. This is where the magic will happen. 
		
		# --------------------------------------------------------------------------------------
		# foreach Assertion... 
		#  		try/catch and keep tabs on pass/fail + exceptions. 
		#   		if fail or exception, keep processing the loop. 
		# when done with try/catch loop of all assertions: 
		#  		if any one of them failed/excepted... 
		#  		THROW "Assertion(s) failed";
		
		
		
		
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
		
		if ($Validate){
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
		
		if ($Configure){
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