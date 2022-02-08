Set-StrictMode -Version 1.0;

function Configure-AdminDbAlerts {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "AdminDbAlerts" -Configure;
}