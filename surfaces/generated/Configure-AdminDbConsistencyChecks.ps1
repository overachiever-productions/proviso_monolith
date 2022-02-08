Set-StrictMode -Version 1.0;

function Configure-AdminDbConsistencyChecks {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "AdminDbConsistencyChecks" -Configure;
}