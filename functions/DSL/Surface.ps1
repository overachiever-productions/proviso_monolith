Set-StrictMode -Version 1.0;

<# 
	SCOPE: 
		A Surface is not a 'true function' - it doesn't DO anything. 
		Instead, it's a container for ordered script-blocks. 
		When run/executed, it creates a (clr) Proviso.Models.Surface object, which contains a list of hierarchical/ordered code bloxks
			that, in turn, will eventually be executed by the Process-Surface method via either the Validate-<SurfaceName> or Configure-<SurfaceName>
			proxies created as wrappers for validate or configure 'calls' against specific surfaces.

	NOTE: 
		Surface sub-funcs have been broken out to enable better PrimalSense while authoring. 
		The actual 'structure' or layout of a Surface and its sub-funcs is as follows: 

				function Surface {
					
					function Setup {}

					function Assertions {
						function Assert {
						}

						# optional, pre-defined assertions: 
						function Assert-UserIsAdminstrator{}
						function Assert-HostIsRunningWindows{}
						etc.
					}

					function Rebase {}

					function Scope {
						function Facet {
							function Expect {}
							function Test {} 
							function Configure {}
						}
					}
				}


#>

# vNEXT: add error-handling/try-catches... 

function Surface {
	param (
		[Parameter(Position = 0, ParameterSetName = "default")]
		[string]$Name,
		[Parameter(Mandatory, Position = 1, ParameterSetName = "default")]
		[ScriptBlock]$Scripts,
		[Switch]$For, # syntactic sugar only... i.e., allows a block of script to accompany a surface 'facet' - for increased context/natural-language
		[ValidateNotNullOrEmpty()]
		[string]$Key
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Surface";
		
		$surfaceFileName = Split-Path -Path $MyInvocation.ScriptName -LeafBase;
		if ($null -eq $Name) {
			$Name = $surfaceFileName;
		}
		
		$surface = New-Object Proviso.Models.Surface($Name, $surfaceFileName, ($MyInvocation.ScriptName).Replace($ProvisoScriptRoot, ".."));
		if (-not ([string]::IsNullOrEmpty($Key))) {
			$surface.AddConfigKey($Key);
		}
	}
	
	process {
		
		& $Scripts;
	}
	
	end {
		
		# vNEXT: force the surface (that's now, nearly, complete) to .Validate() and throw if it's missing key components (like, say, a Facet is missing a Test or something... etc.);
		
		$ProvisoCatalog.AddSurface($surface);
	}
}