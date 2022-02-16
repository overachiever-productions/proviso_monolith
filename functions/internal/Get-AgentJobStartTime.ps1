Set-StrictMode -Version 1.0;

Filter Get-AgentJobStartTime {
	param (
		[Parameter(Mandatory)]
		[string]$SqlServerAgentJob,
		[Parameter(Mandatory)]
		[string]$SqlServerInstanceName
	);
	
	$jobId = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $SqlServerInstanceName) "SELECT [job_id] FROM msdb.dbo.[sysjobs] WHERE [name] = N'$SqlServerAgentJob'; ").job_id;
	
	if (-not ($jobId)) {
		return "<EMPTY>";
	}
	
	$enabled = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $SqlServerInstanceName) "SELECT [enabled] FROM msdb.dbo.[sysjobs] WHERE [name] = N'$SqlServerAgentJob'; ").enabled;
	if ((-not($enabled)) -or ($enabled -eq 0)) {
		return "<DISABLED>";
	}
	
	$scheduleEnabled = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $SqlServerInstanceName) "SELECT 
			ISNULL(MAX(s.[enabled]), 0) [enabled]
		FROM 
			msdb.dbo.sysjobs j 
			INNER JOIN msdb.dbo.[sysjobschedules] js ON [j].[job_id] = [js].[job_id]
			INNER JOIN msdb.dbo.[sysschedules] s ON [js].[schedule_id] = [s].[schedule_id]
		WHERE 
			j.[name] = N'$SqlServerAgentJob'; ").enabled;
	
	if ((-not($scheduleEnabled)) -or ($scheduleEnabled -eq 0)) {
		return "<SCHEDULE_DISABLED>";
	}
	
	$scheduleCount = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $SqlServerInstanceName) "SELECT 
			ISNULL(COUNT(*), 0) [count]
		FROM 
			msdb.dbo.sysjobs j 
			INNER JOIN msdb.dbo.[sysjobschedules] js ON [j].[job_id] = [js].[job_id]
			INNER JOIN msdb.dbo.[sysschedules] s ON [js].[schedule_id] = [s].[schedule_id]
		WHERE 
			j.[name] = N'$SqlServerAgentJob'; ").count;
	
	if ($scheduleCount -eq 0) {
		return "<NO_SCHEDULE>";
	}
	
	if ($scheduleCount -gt 1) {
		return "<$count_SCHEDULES>";
	}
	
	$rawStart = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $SqlServerInstanceName) "SELECT 
			RIGHT(N'000000' + CAST([s].[active_start_time] AS sysname), 6) [start]
		FROM 
			msdb.dbo.sysjobs j 
			INNER JOIN msdb.dbo.[sysjobschedules] js ON [j].[job_id] = [js].[job_id]
			INNER JOIN msdb.dbo.[sysschedules] s ON [js].[schedule_id] = [s].[schedule_id]
		WHERE 
			j.[name] = N'$SqlServerAgentJob'; ").start;
	
	$startTime = "$($rawStart.Substring(0, 2)):$($rawStart.Substring(2, 2)):$($rawStart.Substring(4, 2))";
	
	return $startTime;
}