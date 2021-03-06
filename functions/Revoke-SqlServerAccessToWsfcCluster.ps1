Set-StrictMode -Version 1.0;

function Revoke-SqlServerAccessToWsfcCluster {
	
	# Only disable IF enabled:
	$output = Invoke-SqlCmd -Query "SELECT SERVERPROPERTY('IsHadrEnabled') [result];";
	
	if ($output.result -eq 1) {
		$machineName = $env:COMPUTERNAME;
		
		Disable-SqlAlwaysOn -Path SQLSERVER:\SQL\$machineName\DEFAULT -Force;
		
		#Once that's done, we'll almost certainly have to restart the SQL Server Agent cuz, again, SqlPS sucks... 
		$agentStatus = (Get-Service SqlServerAgent).Status;
		
		if ($agentStatus -ne 'Running') {
			Start-Service SqlServerAgent;
		}
	}
}