Set-StrictMode -Version 1.0;

function Validate-AdminDbInstanceSettings {
	
	Validate-MethodUsage -MethodName "Validate";

	Process-Surface -SurfaceName "AdminDbInstanceSettings" ;
}