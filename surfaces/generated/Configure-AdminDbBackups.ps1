Set-StrictMode -Version 1.0;

function Configure-AdminDbBackups {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "AdminDbBackups" -Configure;
}