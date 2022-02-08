Set-StrictMode -Version 1.0;

function Validate-NetworkAdapters {
	
	Validate-MethodUsage -MethodName "Validate";

	Process-Surface -SurfaceName "NetworkAdapters" ;
}