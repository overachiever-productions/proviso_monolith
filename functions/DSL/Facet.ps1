Set-StrictMode -Version 1.0;

<# 
	SCOPE: 
		A facet IS NOT a true function. 
		It's a container for ordered script-blocks. 
			It provides a hierarchical means of defining what blocks of code should be allocated/assigned to various PROCESSING tasks
			when working through VALIDATING and/or CONFIGURING a given Facet. 


	FUNCTIONALITY: 
		When a 'Facet' is run/imported, it doesn't 'DO' anything. 
			Instead, whenever a facet is run/imported, it creates a Proviso.Models.Facet object - which is a list of ordered code-blocks
					that are, in turn, stored/managed in a (Singleton) Proviso.Models.FacetManager. 
				Surrogate/Facade methods for Verify-<FacetName> and Configure-<FacetName> are then created (during module import/spin up)
					for each facet which act as simple 'wrappers'/proxies (DSL syntactic sugar) that then make calls down into Process-Facet. 

#>

# vNEXT: add error-handling/try-catches... 
# vNEXT: before assignment of inputs/code-blocks to Proviso.Models (of any kind), do the following: 
# 		verify that the 'call-stack' is correct and as expected - i.e., that rebase is a member of facet or that Test is a member of Definition, definitions, facet
# 			and so on. 
# 				ultimately, build a Confirm-CallStackPlacement() func that knows how to do this stuff.


# vNEXT: should a Facet OUTPUT something? maybe dump a Context object into the mix? 
# 		that way a workflow could EASILY examine the outcome/output of a Facet-Operation. 
# 			ARGUABLY, it totally should - in the sense that a Facet should return/output some sort of full-blown object with details about exceptions/errors and the lot. 
#  		the only rub would be ... my idea to do something like: 
#  				> With "something here" | Secured-By $thisObject | Process {
#					Validate-ThisFacet;
#					validate-ThatFacet; 
#					AndSo-On
#				};
# 		though, arguably, the way the above would work is ... 
# 			that I'd either
# 				a) make 'Process' (or whatever it is called) a 'wrapper' around Process-Facet calls
# 					such that it'd keep a COLLECTION of 'FacetOutcome' objects (ordered and by facet-name/operation)
# 				or 
# 				b) i'd look at making some sort of 'follow-on' object... 
# 				like 
# 					> With "eetc" | Process { Validate-This; Validate-That; } | Results-As $output;

#  	 		and.. that's not a terrible flow ANYHOW.  i.e., Results-As would be a bit different than Result-As (or maybe Outcome-As)
# 										as in, Result_S_-As would be plural/many, the other would be singular. 
# 									the rub here though is that ... this whole thing 
# 						VIOLATEs what would come normal in powershell, being: 
# 							> $results = With "such and such" | Secured-By $something | Process { Validate-This; Validate-That; };
# 							or 
# 							> $results = With "path.psd1" | Secured-By $secretsManager | Validate-ServerName;

#  so... i think: 
# 			a. I SHOULD return results. 
# 			b. this is easy enough to do for 'Process' (i.e., whatever 'verb' or whatever I end up using to tackle multiples)
# 				... via option A above - i.e 'Process' would simply 'wrap' and collect outputs of the above. 
# 			c. I should probably fully EMBRACE $outcome = With "something" | Validate-X. 
#   	    d. Arguably... users could ALSO grab outcomes as: 
# 						> With "sdfdsf" | Validate-Xxxx; 
# 						> $results = Last-ProvisoOutcome; -- i.e., some sort of 'static' or $script/$global 'last result' as a means of grabbing those after the fact... 

function Facet {
	
	param (
		[Parameter(Position = 0, ParameterSetName = "default")]
		[string]$Name,
		[Parameter(Mandatory, Position = 1, ParameterSetName = "default")]
		[ScriptBlock]$Scripts
	);
	
	begin {
		Limit-ValidProvisoDSL -MethodName "Facet" -AsFacet;
		
		$facetFileName = Split-Path -Path $MyInvocation.ScriptName -LeafBase;
		if ($null -eq $Name) {
			$Name = $facetFileName;
		}
		
		$facet = New-Object Proviso.Models.Facet($Name, $facetFileName, ($MyInvocation.ScriptName).Replace($script:provisoRoot, ".."));
	}
	
	process {
		
		function Assertions {
			param (
				[ScriptBlock]$Assertions
			);
			
			Limit-ValidProvisoDSL -MethodName "Assertions" -AsFacet;
			
			function Assert {
				param (
					[Parameter(Position = 0)]
					[string]$Description,
					[Parameter(Position = 1)]
					[ScriptBlock]$AssertBlock,
					[Alias("NotFatal","UnFatal", "Informal", "")]
					[Switch]$NonFatal = $false 
				);
				
				Limit-ValidProvisoDSL -MethodName "Assert" -AsFacet;
				
				$assertion = New-Object Proviso.Models.Assertion($Description, $Name, $AssertBlock, $NonFatal);
				$facet.AddAssertion($assertion);
			}
			
			# vNEXT: figure out how to constrain inputs here - as per: https://powershellexplained.com/2017-03-13-Powershell-DSL-design-patterns/#restricted-dsl
			# 		oddly, I can't use a ScriptBlock literal here - i.e., i THINK I could use a string, but not a block... so, MAYBE? convert the block to a string then 'import' it that way to ensure it's constrained?
#			$validatedAssertions = [ScriptBlock]::Create("DATA -SupportedCommand Assert {$Assertions}");
#			& $validatedAssertions
			& $Assertions;
			
		}
		
		function Rebase {
			param (
				[scriptblock]$RebaseBlock
			);
			
			Limit-ValidProvisoDSL -MethodName "Rebase" -AsFacet;
			
			$rebase = New-Object [Proviso.Models.Rebase]($RebaseBlock, $Name);
			$facet.AddRebase($rebase);
		}
		
		function Definitions {
			param (
				[Parameter(Mandatory)]
				[ScriptBlock]$Definitions
			);
			
			Limit-ValidProvisoDSL -MethodName "Definitions" -AsFacet;
			
			function Definition {
				param (
					[Parameter(Mandatory, Position = 0, ParameterSetName = "named")]
					[string]$Description,
					[string]$Expect, 	# optional mechanism for handing in Expect details...
					[Parameter(Mandatory, Position = 2, ParameterSetName = "named")]
					[ScriptBlock]$DefinitionBlock
				)
				
				begin {
					Limit-ValidProvisoDSL -MethodName "Definition" -AsFacet;
					$definition = New-Object Proviso.Models.Definition($Description);
				}
				
				process {
					
					#region vNEXT
					# vNEXT: MIGHT make sense to have an optional 'func' called Validate that returns a ValidationOutput object with .Expected and .Actual values
					#  		i.e., my idea of having distinct 'funcs' for Expect and Test might end up being a bit of a bitch. 
					# 			in that it might be hard to pull off with 2 DISTINCT bodies of text/code (e.g., what if one returns "ADMINISTRATOR" and the other returns ADMINISTRATOR?)
					# 				that'd suck
					# 			So, the idea is that a 'Validate' block could/would run some comparisons and "expect/require" a ValidationOutput result as the outcome. 
					# 				and said ValidationOutput would provide .Expected and .Actual values along with .Pass or whatever... 
					#endregion
					function Expect {
						param (
							[ScriptBlock]$ExpectBlock
						);
						
						Limit-ValidProvisoDSL -MethodName "Expect" -AsFacet;
						$definition.AddExpect($ExpectBlock);
					}
					
					function Test {
						param (
							[ScriptBlock]$TestBlock
						);
						
						Limit-ValidProvisoDSL -MethodName "Test" -AsFacet;
						$definition.AddTest($TestBlock);
					}
					
					function Configure {
						param (
							[ScriptBlock]$ConfigureBlock
						);
						
						Limit-ValidProvisoDSL -MethodName "Configure" -AsFacet;
						$definition.AddConfiguration($ConfigureBlock)
					}
					
					& $DefinitionBlock;
				}
				
				end {
					$facet.AddDefinition($definition);
				}
			}
			
			& $Definitions;
		}
		
		& $Scripts;
	}
	
	end {
		$facetManager = Get-ProvisoFacetManager;
		$facetManager.AddFacet($facet);
	}
}


# ---------------------------------------------------------------------------------------------------------
# Examples of spinning up CLR objects:
# ---------------------------------------------------------------------------------------------------------
#	$facetManager = [Proviso.Models.FacetManager]::GetInstance();
#	Write-Host $facetManager.GetStuff();
#	
#	return;
#	$block = {
#		Write-Host "this is a nested code block";
#		$x = 12;
#	}
#	
#	$assertion = New-Object Proviso.Models.Assertion("my assertion", "Facet Name Here",  $block);
#	Write-Host "Assertion.Name: $($assertion.Name) ";
#	Write-Host "Assertion.ScriptBlock $($assertion.ScriptBlock) ";
#	
#	$outcome = New-Object Proviso.Models.AssertionOutcome($true, $null);
#	$assertion.AssignOutcome($outcome);
#	
#	Write-Host "Assertion.Outcome: $($assertion.Outcome.Passed)";
#	return;


# ---------------------------------------------------------------------------------------------------------
# Examples of interacting with the facet manager:
# ---------------------------------------------------------------------------------------------------------
#	Write-Host "`r-------------------------------------------------------------------------------------------";
#	$facetManager = Get-ProvisoFacetManager;
#	Write-Host "FacetManager.Count: $($facetManager.FacetCount)";
#
#	[Proviso.Models.Facet]$f = $facetManager.GetFacet("ServerName");
#	Write-Host $f.SourceFile;