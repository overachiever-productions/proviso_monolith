Set-StrictMode -Version 1.0;

function Configure-AdminDbHistory {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "AdminDbHistory" -Configure;
}