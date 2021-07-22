Set-StrictMode -Version 1.0;

function Wait-ForSQLAccessAfterRestart {
	# TODO: callers should be able to get a true or false for 'succeeded' or not (or 0 | 1 or whatever)... 
	# NOTE: need to 'force'/ensure that the PS SQLServer module is installed - i.e., it's a dependency here... 
	
	param (
		[int]$TimeoutSeconds = 120
	);
	
	$rowCount = -1;
	$startTime = Get-Date;
	Write-Host "Initiating access into SQL Server...";
	
	do {
		try {
			
			$query = (Invoke-SqlCmd -Query "SELECT COUNT(*) [output] FROM [msdb].dbo.[sysjobhistory];" -ErrorAction Stop -ConnectionTimeout 5 -QueryTimeout 5);
			$rowCount = $query.output;
		}
		catch {
			$rowCount = -1;
		}
		
		Write-Host "    Server not available - waiting ~2 secconds...";
		Start-Sleep -Milliseconds 2100;
		
		$duration = (Get-Date) - $startTime;
	}
	until (($rowCount -ge 0) -or ($duration.TotalSeconds -gt $TimeoutSeconds));
	
	if ($rowCount -gt 0) {
		Write-Host "Server Available.";
	}
	else {
		Write-Host "Connection attempt timed out after $TimeoutSeconds seconds.";
	}
}