Set-StrictMode -Version 1.0;

function Validate-FirewallRules {
	
	Validate-MethodUsage -MethodName "Validate";

	Process-Surface -SurfaceName "FirewallRules" ;
}