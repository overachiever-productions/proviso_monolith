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

function Facet {
	
	param (
		[Parameter(Position = 0, ParameterSetName = "default")]
		[string]$Name,
		[Parameter(Mandatory, Position = 1, ParameterSetName = "default")]
		[ScriptBlock]$Scripts
	);
	
	begin {
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
			
			function Assert {
				param (
					[Parameter(Position = 0)]
					[string]$Description,
					[Parameter(Position = 1)]
					[ScriptBlock]$AssertBlock,
					[Alias("NotFatal","UnFatal", "Informal", "")]
					[Switch]$NonFatal = $false 
				);
				
				$assertion = New-Object Proviso.Models.Assertion($Description, $Name, $AssertBlock, $NonFatal);
				$facet.AddAssertion($assertion);
			}
			
			& $Assertions;
		}
		
		function Rebase {
			param (
				[scriptblock]$RebaseBlock
			);
			
			$rebase = New-Object [Proviso.Models.Rebase]($RebaseBlock, $Name);
			$facet.AddRebase($rebase);
		}
		
		function Definitions {
			param (
				[Parameter(Mandatory)]
				[ScriptBlock]$Definitions
			);
			
			function Definition {
				param (
					[Parameter(Mandatory, Position = 0, ParameterSetName = "named")]
					[string]$Description,
					[string]$Expect, 	# optional mechanism for handing in Expect details...
					[Parameter(Mandatory, Position = 2, ParameterSetName = "named")]
					[ScriptBlock]$DefinitionBlock
				)
				
				begin {
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
						
						$definition.AddExpect($ExpectBlock);
					}
					
					function Test {
						param (
							[ScriptBlock]$TestBlock
						);
						
						$definition.AddTest($TestBlock);
					}
					
					function Configure {
						param (
							[ScriptBlock]$ConfigureBlock
						);
						
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