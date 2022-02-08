Set-StrictMode -Version 1.0;

function Configure-AdminDb {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "AdminDb" -Configure;
}