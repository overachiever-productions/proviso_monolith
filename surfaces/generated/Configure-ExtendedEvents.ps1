Set-StrictMode -Version 1.0;

function Configure-ExtendedEvents {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "ExtendedEvents" -Configure;
}