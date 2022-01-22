Set-StrictMode -Version 1.0;

# yeah. the name of this thing is a mouth-ful... but it does what it says... 
filter Report-SqlServerAgentJobEnabledState {
	param (
		[Parameter(Mandatory)]
		[string]$SqlServerAgentJob,
		[Parameter(Mandatory)]
		[string]$SqlServerInstanceName
	);
	
	
	$jobExists = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $SqlServerInstanceName) "SELECT [name] FROM msdb.dbo.[sysjobs] WHERE [name] = N'$SqlServerAgentJob'; ").name;
	if (-not ($jobExists)) {
		return;
	}
	
	$enabled = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $SqlServerInstanceName) "SELECT [enabled] FROM msdb.dbo.[sysjobs] WHERE [name] = N'$SqlServerAgentJob'; ").enabled;
	if ($enabled -eq 0) {
		$PVContext.WriteLog("SQL Server Agent Job [$SqlServerAgentJob] exists on SQL Server Instance [$SqlServerInstanceName] - but is DISABLED.", "Important");
		return $false;
	}
	
	$scheduleEnabled = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $SqlServerInstanceName) "SELECT 
						MAX(s.[enabled]) [enabled]
					FROM 
						msdb.dbo.sysjobs j 
						INNER JOIN msdb.dbo.[sysjobschedules] js ON [j].[job_id] = [js].[job_id]
						INNER JOIN msdb.dbo.[sysschedules] s ON [js].[schedule_id] = [s].[schedule_id]
					WHERE 
						j.[name] = N'$SqlServerAgentJob'; ").enabled;
	
	if ($scheduleEnabled -eq 0) {
		$PVContext.WriteLog("SQL Server Agent Job [$SqlServerAgentJob] exists on SQL Server Instance [$SqlServerInstanceName] - but does NOT have a Job Schedule that is ENABLED.", "Important");
		return $false;
	}
	
	return $true;
}