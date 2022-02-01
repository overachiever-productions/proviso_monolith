Set-StrictMode -Version 1.0;

function Validate-WindowsPreferences {
	
	param (
		[Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
		[PSCustomObject]$Config
	);
	
	Validate-MethodUsage -MethodName "Validate";

	if(($global:PVExecuteActive -eq $true) -or ($global:PVRunBookActive -eq $true)) {
		if($null -eq $Config) {
			$Config = $global:PVConfig;
		}
	}

	Process-Surface -SurfaceName "WindowsPreferences" -Config $Config ;
}