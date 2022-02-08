Set-StrictMode -Version 1.0;

function Configure-ExpectedShares {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "ExpectedShares" -Configure;
}