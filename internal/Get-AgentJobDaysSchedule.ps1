Set-StrictMode -Version 1.0;

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
			bit_map int 
		);
		INSERT INTO @days (
			[abbreviation],
			[day_name],
			[bit_map]
		)
		VALUES	
			(N'Su', N'Sunday', 1),
			(N'M', N'Monday', 2),
			(N'Tu', N'Tuesday', 4),
			(N'W', N'Wednesday', 8),
			(N'Th', N'Thursday', 16),
			(N'F', N'Friday', 32),
			(N'Sa', N'Saturday', 64);

		DECLARE @matchedDays sysname = N'';

		SELECT 
			@matchedDays = @matchedDays + CASE WHEN (@interval & [bit_map]) = [bit_map] THEN [abbreviation] + N',' ELSE N'' END
		FROM 
			@days
		ORDER BY 
			[bit_map];

		IF LEN(@matchedDays) > 1 BEGIN 
			SELECT @matchedDays = SUBSTRING(@matchedDays, 0, LEN(@matchedDays));
		END;

		SELECT @matchedDays [output]; ").output;
	
	return $executionDays;
}