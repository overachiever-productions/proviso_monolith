Set-StrictMode -Version 1.0;

function Validate-Ssms {
	
	Validate-MethodUsage -MethodName "Validate";

	Process-Surface -SurfaceName "Ssms" ;
}