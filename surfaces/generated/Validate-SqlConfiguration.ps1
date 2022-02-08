Set-StrictMode -Version 1.0;

function Validate-SqlConfiguration {
	
	Validate-MethodUsage -MethodName "Validate";

	Process-Surface -SurfaceName "SqlConfiguration" ;
}