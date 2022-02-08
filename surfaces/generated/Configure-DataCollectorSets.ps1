Set-StrictMode -Version 1.0;

function Configure-DataCollectorSets {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "DataCollectorSets" -Configure;
}