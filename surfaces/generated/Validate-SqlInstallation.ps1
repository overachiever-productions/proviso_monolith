Set-StrictMode -Version 1.0;

function Validate-SqlInstallation {
	
	Validate-MethodUsage -MethodName "Validate";

	Process-Surface -SurfaceName "SqlInstallation" ;
}