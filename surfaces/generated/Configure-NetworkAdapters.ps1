Set-StrictMode -Version 1.0;

function Configure-NetworkAdapters {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "NetworkAdapters" -Configure;
}