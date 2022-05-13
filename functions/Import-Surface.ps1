Set-StrictMode -Version 1.0;


# https://overachieverllc.atlassian.net/browse/PRO-309


<# 
	Scope of this is to allow users of Proviso to define their own Surface
		either as: 
			A. file(s)
			B. on the fly - e.g., $surface = {
				Surface "someNameHere" {
					guts would go here... 
				}
			};

#>

function Import-Surface {
	param (
		[string]$Path,
		[string]$Definition  #TODO: $Definition should probably be a [ScriptBlock]
	);
	
	begin {
		# make sure path or definition - not both. (probably use ... parametersets for this kind of stuff). 
		# if -Path and is valid, 
		# 		set -Definition = Get-Content -Path... -> and then do a ScriptBlock.Create() or whatever... 
		
	}
	
	process {
		# (make sure to do a foreach in $Definition(s)... )
		#  i.e., if someone spams in > 1 $Path or > 1 $Definition... need to process them all ... not just 'scalar/1x'
		
		# basically: 
		# 1. run/import the Surface: 
		& $Definition;
		
		# (copied out of ... build_test.ps1/Proviso.psm1)
		$validateSurface = {
			param (
				[Parameter(Mandatory)]
				[string]$SurfaceName,
				[Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
				[PSCustomObject]$Config
			);
			
			Process-Surface -SurfaceName $SurfaceName -Config $Config -Validate;
		};
		
		$configureSurface = {
			param (
				[Parameter(Mandatory)]
				[string]$SurfaceName,
				[Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
				[PSCustomObject]$Config
			);
			
			Process-Surface -SurfaceName $SurfaceName -Config $Config -Configure;
		};
		
		# figure out how to get  the surface-name from the surface itself... 
		# then use it to define the names... 
#		$validateName = "Validate-$($file.Basename)";
#		$configureName = "Configure-$($file.Basename)";
		
		Set-Item -Path "Function:$validateName" -Value $validateSurface;
		Set-Item -Path "Function:$configureName" -Value $configureSurface;
		
	}
	
	end {
		
	}
}