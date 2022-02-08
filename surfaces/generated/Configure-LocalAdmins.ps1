Set-StrictMode -Version 1.0;

function Configure-LocalAdmins {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "LocalAdmins" -Configure;
}