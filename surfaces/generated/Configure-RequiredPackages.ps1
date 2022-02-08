Set-StrictMode -Version 1.0;

function Configure-RequiredPackages {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "RequiredPackages" -Configure;
}