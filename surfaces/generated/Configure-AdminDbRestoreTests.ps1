Set-StrictMode -Version 1.0;

function Configure-AdminDbRestoreTests {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "AdminDbRestoreTests" -Configure;
}