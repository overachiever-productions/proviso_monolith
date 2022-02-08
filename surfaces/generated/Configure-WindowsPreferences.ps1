Set-StrictMode -Version 1.0;

function Configure-WindowsPreferences {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "WindowsPreferences" -Configure;
}