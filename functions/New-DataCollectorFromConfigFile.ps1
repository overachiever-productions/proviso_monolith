Set-StrictMode -Version 1.0;

function New-DataCollectorFromConfigFile {
	
	param (
		[string]$DataCollectorName,
		[string]$FullPathToXmlConfigFile
	);
	
	$status = Get-DataCollectorStatus $DataCollectorName;
	
	if ($status -ne "NotFound") {
		if ($status -eq "Running") {
			Invoke-Expression "logman.exe stop `"$DataCollectorName`"";
		}
		
		Invoke-Expression "logman.exe delete `"$DataCollectorName`"";
	}
	
	Invoke-Expression "logman.exe import `"$DataCollectorName`" -xml `"$FullPathToXmlConfigFile`"";
	
	if ($status -eq "Running") {
		# give ourselves a few seconds - because, otherwise, we'll likely try to overwrite an existing file: 
		Write-Host "Waiting for 8 seconds ... ";
		Start-Sleep -Milliseconds 8200;
		
		Invoke-Expression "logman.exe start `"$DataCollectorName`"";
	}
}