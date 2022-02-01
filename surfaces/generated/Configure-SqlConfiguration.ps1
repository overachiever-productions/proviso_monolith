Set-StrictMode -Version 1.0;

function Configure-SqlConfiguration {
	
	param (
		[Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
		[PSCustomObject]$Config
	);
	
	Validate-MethodUsage -MethodName "Configure";

	if(($global:PVExecuteActive -eq $true) -or ($global:PVRunBookActive -eq $true)) {
		if($null -eq $Config) {
			$Config = $global:PVConfig;
		}
	}

	Process-Surface -SurfaceName "SqlConfiguration" -Config $Config -Configure;
}