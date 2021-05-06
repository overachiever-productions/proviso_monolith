Set-StrictMode -Version 1.0;

function New-LocalSqlIniFilePath {
	$rootPath = "C:\Scripts";
	
	if(!(Test-Path -Path $rootPath)) {
		Mount-Directory -Path $rootPath;
	}
	
	[int]$fileNumber = 0;
	[string]$finalPath = "";
	[string]$hostName = $env:COMPUTERNAME;
	
	while ([string]::IsNullOrEmpty($finalPath)) {
		[string]$marker = "_$($fileNumber)";
		
		if ($marker -eq "_0") {
			$marker = "";
		}
		[string]$newPath = Join-Path -Path $rootPath -ChildPath "$($hostName)_SQL_CONFIG$($marker).ini";
		
		if (!(Test-Path -Path $newPath)) {
			$finalPath = $newPath;
		}
		
		$fileNumber++;
		if ($fileNumber -gt 20) {
			break;
		}
	}
	
	if ($finalPath -eq $null) {
		throw "Too many SQL_CONFIG_##.ini files found in C:\Scripts directory. Can't save .ini settings. Terminating.";
	}
	
	return $finalPath;
}