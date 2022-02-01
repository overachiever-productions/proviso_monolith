Set-StrictMode -Version 1.0;

function Provision-AdminDbDatabaseMail {
	
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

	Process-Surface -SurfaceName "AdminDbDatabaseMail" -Config $Config -Provision;
}