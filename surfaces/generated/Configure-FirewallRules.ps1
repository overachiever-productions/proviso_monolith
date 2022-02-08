Set-StrictMode -Version 1.0;

function Configure-FirewallRules {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "FirewallRules" -Configure;
}