Set-StrictMode -Version 1.0;

function Stop-SQLServerAndAgent {
	# TODO: account for named instances. 
	
	$sql = Get-Service MSSQLSERVER;
	
	if ($sql.Status -ne "Stopped") {
		try {
			Stop-Service $sql -Force;
			
			$sql.WaitForStatus('Stopped', '00:00:30');
		}
		catch [System.ServiceProcess.TimeoutException] {
			throw "Timeout Exception Encountered - SQL Server Service could/would NOT stop within 30 seconds.";
		}
		catch {
			throw "Unexpected Problem Encountered: " + $PSItem.Exception.Message;
		}
	}
	
	Write-Host "SQL Server Service Stopped.";
}