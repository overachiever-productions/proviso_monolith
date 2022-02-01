Set-StrictMode -Version 1.0;

function Provision-TestingSurface {
	
	param (
		[Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
		[PSCustomObject]$Config
	);
	
	Validate-MethodUsage -MethodName "Provision";

	if(($global:PVExecuteActive -eq $true) -or ($global:PVRunBookActive -eq $true)) {
		if($null -eq $Config) {
			$Config = $global:PVConfig;
		}
	}

	Process-Surface -SurfaceName "TestingSurface" -Config $Config -Provision;
}