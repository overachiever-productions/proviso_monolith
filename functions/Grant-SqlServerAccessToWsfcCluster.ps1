Set-StrictMode -Version 1.0;

function Grant-SqlServerAccessToWsfcCluster {
	# Grant SQL Server the Ability to Leverage underlying WSFC: 
	# Only enable IF not already enabled:
	$output = Invoke-SqlCmd -Query "SELECT SERVERPROPERTY('IsHadrEnabled') [result];";
	
	if ($output.result -ne 1) {
		$machineName = $env:COMPUTERNAME;
		
		Enable-SqlAlwaysOn -Path SQLSERVER:\SQL\$machineName\DEFAULT -Force;
		
		#Once that's done, we'll almost certainly have to restart the SQL Server Agent cuz, again, SqlPS sucks... 
		$agentStatus = (Get-Service SqlServerAgent).Status;
		
		if ($agentStatus -ne 'Running') {
			Start-Service SqlServerAgent;
		}
	}
}