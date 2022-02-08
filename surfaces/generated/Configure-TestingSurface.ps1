Set-StrictMode -Version 1.0;

function Configure-TestingSurface {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "TestingSurface" -Configure;
}