Set-StrictMode -Version 1.0;

function Configure-SqlInstallation {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "SqlInstallation" -Configure;
}