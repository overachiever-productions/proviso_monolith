Set-StrictMode -Version 1.0;

function Configure-ServerName {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "ServerName" -Configure;
}