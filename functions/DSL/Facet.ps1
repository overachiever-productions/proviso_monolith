Set-StrictMode -Version 1.0;

<# 
	SCOPE: 
		A Facet is not a 'true function' - it doesn't DO anything. 
		Instead, it's a container for workflow-ordered script-blocks. 
		When run/executed, it creates a Proviso.Models.Facet object, which contains a list of hierarchical/ordered code bloxks
			that, in turn, will eventually be executed by the Process-Facet method via either the Validate-<FacetName> or Configure-<FacetName>
			proxies that are contained as execution pipelines for the code/definitions within an actual facet. 


	NOTE: 
		Facet sub-funcs have been broken out to enable better PrimalSense while authoring. 
		The actual 'structure' or layout of a Facet and its sub-funcs is as follows: 

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
		[ScriptBlock]$Scripts,
		[Switch]$For # syntactic sugar only... 
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
		
		& $Scripts;
	}
	
	end {
		$ProvisoFacetsCatalog.AddFacet($facet);
	}
}