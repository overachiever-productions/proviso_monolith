﻿Set-StrictMode -Version 1.0;

filter Get-AgentJobDaysSchedule {
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
			[s].[freq_type],
			[s].[freq_interval]
		FROM 
			msdb.dbo.sysjobs j 
			INNER JOIN msdb.dbo.[sysjobschedules] js ON [j].[job_id] = [js].[job_id]
			INNER JOIN msdb.dbo.[sysschedules] s ON [js].[schedule_id] = [s].[schedule_id]
		WHERE 
			j.[name] = N'$SqlServerAgentJob'; ");
	
	if ($frequencyDetails.freq_type -ne 8) {
		return "<NOT_WEEKLY>";
	}
	
	$frequency = $frequencyDetails.freq_interval;
	
	$executionDays = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $SqlServerInstanceName) "DECLARE @interval int = $frequency;
		DECLARE @days table (
			abbreviation sysname,
			day_name sysname, 
			bit_map int, 
			sort_order int
		);
		INSERT INTO @days (
			[abbreviation],
			[day_name],
			[bit_map], 
			[sort_order]
		)
		VALUES	
			(N'Su', N'Sunday', 1, 99),
			(N'M', N'Monday', 2, 1),
			(N'Tu', N'Tuesday', 4, 2),
			(N'W', N'Wednesday', 8, 3),
			(N'Th', N'Thursday', 16, 4),
			(N'F', N'Friday', 32, 5),
			(N'Sa', N'Saturday', 64, 6);

		DECLARE @matchedDays sysname = N'';

		SELECT 
			@matchedDays = @matchedDays + CASE WHEN (@interval & [bit_map]) = [bit_map] THEN [abbreviation] + N',' ELSE N'' END
		FROM 
			@days
		ORDER BY 
			[sort_order];

		IF LEN(@matchedDays) > 1 BEGIN 
			SELECT @matchedDays = SUBSTRING(@matchedDays, 0, LEN(@matchedDays));
		END;

		SELECT @matchedDays [output]; ").output;
	
	return $executionDays;
}

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

filter Get-AgentJobStartTime {
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

filter Get-AgentJobStepBody {
	param (
		[Parameter(Mandatory)]
		[string]$SqlServerAgentJob,
		[Parameter(Mandatory)]
		[string]$JobStepName,
		[Parameter(Mandatory)]
		[string]$SqlServerInstanceName
	);
	
	$jobId = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $SqlServerInstanceName) "SELECT [job_id] FROM msdb.dbo.[sysjobs] WHERE [name] = N'$SqlServerAgentJob'; ").job_id;
	
	if (-not ($jobId)) {
		return "<EMPTY>";
	}
	
	$body = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT 
			[command] 
		FROM 
			[msdb].dbo.[sysjobsteps] 
		WHERE 
			[step_name] = N'$JobStepName' 
			AND [job_id] = '$jobId'; ").command;
	
	if ($body) {
		return $body;
	}
	
	return "<EMPTY_BODY>";
}