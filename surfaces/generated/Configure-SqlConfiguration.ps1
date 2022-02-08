Set-StrictMode -Version 1.0;

function Configure-SqlConfiguration {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "SqlConfiguration" -Configure;
}