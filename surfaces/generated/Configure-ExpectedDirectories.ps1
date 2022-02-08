Set-StrictMode -Version 1.0;

function Configure-ExpectedDirectories {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "ExpectedDirectories" -Configure;
}