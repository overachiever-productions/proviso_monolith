Set-StrictMode -Version 1.0;

<# 
	Scope of this is to allow users of Proviso to define their own Facets
		either as: 
			A. file(s)
			B. on the fly - e.g., $facet = {
				facet "someNameHere" {
					guts would go here... 
				}
			};

#>

function Import-Facet {
	param (
		[string]$Path,
		[string]$Definition
	);
	
	begin {
		# make sure path or definition - not both. (probably use ... parametersets for this kind of stuff). 
		# if -Path and is valid, 
		# 		set -Definition = Get-Content -Path... 
		
	}
	
	process {
		# (make sure to do a foreach in $Definition(s)... )
		
		# basically: 
		# 1. run/import the facet: 
		& $Definition;
		
		# (copied out of ... build_test.ps1/Proviso.psm1)
		$validateFacet = {
			param (
				[Parameter(Mandatory)]
				[string]$FacetName,
				[Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
				[PSCustomObject]$Config
			);
			
			Process-Facet -FacetName $FacetName -Config $Config -Validate;
		};
		
		$configureFacet = {
			param (
				[Parameter(Mandatory)]
				[string]$FacetName,
				[Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
				[PSCustomObject]$Config
			);
			
			Process-Facet -FacetName $FacetName -Config $Config -Configure;
		};
		
		# figure out how to get  the facet-name from the facet itself... 
		# then use it to define the names... 
#		$validateName = "Validate-$($file.Basename)";
#		$configureName = "Configure-$($file.Basename)";
		
		Set-Item -Path "Function:$validateName" -Value $validateFacet;
		Set-Item -Path "Function:$configureName" -Value $configureFacet;
		
	}
	
	end {
		
	}
}