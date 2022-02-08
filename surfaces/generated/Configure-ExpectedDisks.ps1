Set-StrictMode -Version 1.0;

function Configure-ExpectedDisks {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "ExpectedDisks" -Configure;
}