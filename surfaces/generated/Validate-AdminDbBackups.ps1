Set-StrictMode -Version 1.0;

function Validate-AdminDbBackups {
	
	Validate-MethodUsage -MethodName "Validate";

	Process-Surface -SurfaceName "AdminDbBackups" ;
}