Set-StrictMode -Version 1.0;

function New-DataCollectorFromConfigFile {
	
	param (
		[string]$Name,
		[string]$ConfigFilePath
	);
	
	$status = Get-DataCollectorStatus $Name;
	
	if ($status -ne "NotFound") {
		if ($status -eq "Running") {
			Invoke-Expression "logman.exe stop `"$Name`"";
		}
		
		Invoke-Expression "logman.exe delete `"$Name`"";
	}
	
	Invoke-Expression "logman.exe import `"$Name`" -xml `"$ConfigFilePath`"";
	
	if ($status -eq "Running") {
		# give ourselves a few seconds - because, otherwise, we'll likely try to overwrite an existing file: 
		Write-Host "Waiting for 8 seconds ... ";
		Start-Sleep -Milliseconds 8200;
		
		Invoke-Expression "logman.exe start `"$Name`"";
	}
}