Set-StrictMode -Version 1.0;

<# 
	SCOPE: 
		A Facet is not a 'true function' - it doesn't DO anything. 
		Instead, it's a container for ordered script-blocks. 
		When run/executed, it creates a (clr) Proviso.Models.Facet object, which contains a list of hierarchical/ordered code bloxks
			that, in turn, will eventually be executed by the Process-Facet method via either the Validate-<FacetName> or Configure-<FacetName>
			proxies created as wrappers for validate or configure 'calls' against specific facets.

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
		[Switch]$For, # syntactic sugar only... i.e., allows a block of script to accompany a facet 'definition' - for increased context/natural-language
		[ValidateNotNullOrEmpty()]
		[string]$Key
	);
	
	begin {
		Limit-ValidProvisoDSL -MethodName "Facet" -AsFacet;
		
		$facetFileName = Split-Path -Path $MyInvocation.ScriptName -LeafBase;
		if ($null -eq $Name) {
			$Name = $facetFileName;
		}
		
		$facet = New-Object Proviso.Models.Facet($Name, $facetFileName, ($MyInvocation.ScriptName).Replace($ProvisoScriptRoot, ".."));
		if (-not ([string]::IsNullOrEmpty($Key))) {
			$facet.AddConfigKey($Key);
		}
	}
	
	process {
		
		& $Scripts;
	}
	
	end {
		
		# vNEXT: force the facet (that's now, nearly, complete) to .Validate() and throw if it's missing key components (like, say, a Definition is missing a Test or something... etc.);
		
		$ProvisoFacetsCatalog.AddFacet($facet);
	}
}