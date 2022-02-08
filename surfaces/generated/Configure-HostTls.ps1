Set-StrictMode -Version 1.0;

function Configure-HostTls {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "HostTls" -Configure;
}