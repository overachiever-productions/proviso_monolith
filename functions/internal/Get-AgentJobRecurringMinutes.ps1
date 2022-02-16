Set-StrictMode -Version 1.0;

filter Get-AgentJobRecurringMinutes {
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
	if ((-not ($enabled)) -or ($enabled -eq 0)) {
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
	
	if ((-not ($scheduleEnabled)) -or ($scheduleEnabled -eq 0)) {
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
	
	$frequencyDetails = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $SqlServerInstanceName) "SELECT 
			[s].[freq_subday_type],
			[s].[freq_subday_interval]
		FROM 
			msdb.dbo.sysjobs j 
			INNER JOIN msdb.dbo.[sysjobschedules] js ON [j].[job_id] = [js].[job_id]
			INNER JOIN msdb.dbo.[sysschedules] s ON [js].[schedule_id] = [s].[schedule_id]
		WHERE 
			j.[name] = N'$SqlServerAgentJob'; ");
	
	if ($frequencyDetails.freq_subday_type -ne 4) {
		return "<NOT_DAILY>";
	}
	
	$frequency = $frequencyDetails.freq_subday_interval;
	
	return Pluralize-Vector -Unit $frequency -UnitType "minute";
}