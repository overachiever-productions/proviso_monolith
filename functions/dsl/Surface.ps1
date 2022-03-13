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

					function Aspect -Scope "xxx" {
						function Facet {
							function Expect {}
							function Test {} 
							function Configure {}
						}

						function Build {  # up to 1x per Aspect... 

							function Deploy {
								
							}
						}
					}
				}


#>

# vNEXT: add error-handling/try-catches... 
# TODO: actually, keep the comments above about the 'structure' of a surface, but put ALL of the child objects into this/single file - that'll boost import/build speed. 

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
		
		$surface.Validate();
		$global:PVCatalog.AddSurface($surface);
	}
}

function Setup {
	param (
		[scriptblock]$SetupBlock
	);
	
	Validate-SurfaceBlockUsage -BlockName "Setup";
	
	$setup = New-Object Proviso.Models.Setup($SetupBlock, $Name);
	$surface.AddSetup($setup);
}

function Assertions {
	param (
		[ScriptBlock]$Assertions
	);
	
	Validate-SurfaceBlockUsage -BlockName "Assertions";
	
	# vNEXT: figure out how to constrain inputs here - as per: https://powershellexplained.com/2017-03-13-Powershell-DSL-design-patterns/#restricted-dsl
	# 		oddly, I can't use a ScriptBlock literal here - i.e., i THINK I could use a string, but not a block... so, MAYBE? convert the block to a string then 'import' it that way to ensure it's constrained?
	#			$validatedAssertions = [ScriptBlock]::Create("DATA -SupportedCommand Assert {$Assertions}");
	#			& $validatedAssertions
	& $Assertions;
}