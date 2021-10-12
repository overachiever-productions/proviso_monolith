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


	LOGICAL ORDERING/LAYOUT (I've broken Facet-sub-funcs out into their own 'files' to help with primalsense while authoring facets: 

		function Facet {
			function Assertions {
				function Assert {
				}
			}

			function Rebase {}

			function Definitions {
				function Definition {
					function Expect {}
					function Test {} 
					function Configure {}
				}
			}
		}


#>

# vNEXT: add error-handling/try-catches... 

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
		
		$facet = New-Object Proviso.Models.Facet($Name, $facetFileName, ($MyInvocation.ScriptName).Replace($ProvisoScriptRoot, ".."));
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
					[Alias("NotFatal", "UnFatal", "Informal", "")]
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
					[string]$Expect, # optional mechanism for handing in Expect details...
					[Parameter(Mandatory, Position = 2, ParameterSetName = "named")]
					[ScriptBlock]$DefinitionBlock
				)
				
				begin {
					Limit-ValidProvisoDSL -MethodName "Definition" -AsFacet;
					$definition = New-Object Proviso.Models.Definition($Description);
				}
				
				process {
					#region vNEXT
					# vNEXT: It MAY (or may not) make sense to allow MULTIPLE Expects. 
					# 		for example, TargetDomain ... could be "" or "WORKGROUP". Both answers are acceptable. 
					# 	there are 2x main problems with this proposition, of course: 
					#		1. How do I end up tweaking the .config to allow 1 or MORE values? (guess I could make arrays? e.g., instead of TargetDomain = "scalar" it could be TargetDomain = @("", "WORKGROUP")
					# 		2. I then have to address how to compare one return value against multiple options. 
					# 			that's easy on the surface - but a bit harder under the covers... 
					# 				specifically:
					# 					- does 1 match of actual vs ALL possibles yield a .Matched = true? 
					# 					or does .Matched = true require that ALL values were matches? ... 
					# 				i.e., this starts to get messy/ugly. 
					# 		3. Yeah... the third out of 2 problems is ... that this tends to overly complicate things... it could spiral out of control quickly.
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
		$ProvisoFacetsCatalog.AddFacet($facet);
	}
}