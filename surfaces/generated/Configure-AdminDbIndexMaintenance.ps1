Set-StrictMode -Version 1.0;

function Configure-AdminDbIndexMaintenance {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "AdminDbIndexMaintenance" -Configure;
}