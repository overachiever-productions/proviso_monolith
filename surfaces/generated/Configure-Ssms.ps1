Set-StrictMode -Version 1.0;

function Configure-Ssms {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "Ssms" -Configure;
}