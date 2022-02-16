Set-StrictMode -Version 1.0;

filter New-DataCollectorSetFromConfigFile {
	param (
		[string]$Name,
		[string]$ConfigFilePath
	);
	
	$status = Get-DataCollectorSetStatus $Name;
	
	if ($status -ne "<EMPTY>") {
		if ($status -eq "Running") {
			Invoke-Expression "logman.exe stop `"$Name`"" | Out-Null;
		}
		
		Invoke-Expression "logman.exe delete `"$Name`"" | Out-Null;
	}
	
	Invoke-Expression "logman.exe import `"$Name`" -xml `"$ConfigFilePath`"" | Out-Null;
	
	# force a wait before attempting start: 
	Start-Sleep -Milliseconds 1800 | Invoke-Expression "logman.exe start `"$Name`"" | Out-Null;
}