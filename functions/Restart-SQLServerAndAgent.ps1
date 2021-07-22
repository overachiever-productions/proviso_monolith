Set-StrictMode -Version 1.0;

function Restart-SQLServerAndAgent {
	# TODO: account for named instances. 
	
	$sql = Get-Service MSSQLSERVER;
	$errors = 0;
	
	if ($sql.Status -ne "Stopped") {
		try{
			Stop-Service $sql -Force;
			$sql.WaitForStatus("Stopped", "00:00:30");
		}
		catch [System.ServiceProcess.TimeoutException] {
			throw "Timeout Exception Encountered - SQL Server Service could/would NOT stop within 30 seconds.";
			$errors = 1;
		}
		catch {
			throw "Unexpected Problem Encountered: " + $PSItem.Exception.Message;
			$errors = 1;
		}
	}
	
	if ($errors -eq 0) {
		Write-Host "SQL Server Service Stopped. Starting SQL Server + SQL Server Agent...";
	}
	
	$errors = 0;
	try {
		Start-Service $sql;
		$sql.WaitForStatus("Running", "00:00:30");
	}
	catch [System.ServiceProcess.TimeoutException] {
		throw "Timeout Exception Encountered - SQL Server Service could/would NOT start within 30 seconds.";
		$errors = 1;
	}
	catch {
		throw "Unexpected Problem Encountered: " + $PSItem.Exception.Message;
		$errors = 1;
	}
	
	if ($errors -eq 0) {
		try {
			$agent = Get-Service SQLSERVERAGENT;
			
			Start-Service $agent;
			$agent.WaitForStatus("Running");
		}
		catch [System.ServiceProcess.TimeoutException] {
			throw "Timeout Exception Encountered - SQL Server Service could/would NOT start within 30 seconds.";
			$errors = 1;
		}
		catch {
			throw "Unexpected Problem Encountered: " + $PSItem.Exception.Message;
			$errors = 1;
		}
		
		if ($errors -eq 0) {
			Write-Host "SQL Server Service + SQL Server Agent Started...";
		}
	}
}