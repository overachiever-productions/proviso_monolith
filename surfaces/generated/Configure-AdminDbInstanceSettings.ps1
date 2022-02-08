Set-StrictMode -Version 1.0;

function Configure-AdminDbInstanceSettings {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "AdminDbInstanceSettings" -Configure;
}