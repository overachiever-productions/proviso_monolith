Set-StrictMode -Version 1.0;

function Validate-TestingSurface {
	
	Validate-MethodUsage -MethodName "Validate";

	Process-Surface -SurfaceName "TestingSurface" ;
}