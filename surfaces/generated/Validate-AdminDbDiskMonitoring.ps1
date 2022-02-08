Set-StrictMode -Version 1.0;

function Validate-AdminDbDiskMonitoring {
	
	Validate-MethodUsage -MethodName "Validate";

	Process-Surface -SurfaceName "AdminDbDiskMonitoring" ;
}