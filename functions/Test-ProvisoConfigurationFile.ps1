Set-StrictMode -Version 1.0;

function Test-ProvisoConfigurationFile {
	param (
		[string]$ConfigPath
	);
	
	if (-not (Test-Path -Path $ConfigPath)) {
		return $null;
	}
	
	$testConfig = Read-ServerDefinitions -Path $ConfigPath -Strict:$false;
	
	if ($testConfig.NetworkDefinitions -ne $null -or $testConfig.TargetServer -ne $null) {
		return $ConfigPath;
	}
}