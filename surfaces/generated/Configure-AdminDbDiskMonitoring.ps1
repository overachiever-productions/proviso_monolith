Set-StrictMode -Version 1.0;

function Configure-AdminDbDiskMonitoring {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "AdminDbDiskMonitoring" -Configure;
}