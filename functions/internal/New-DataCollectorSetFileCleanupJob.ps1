Set-StrictMode -Version 1.0;

filter New-DataCollectorSetFileCleanupJob {
	param (
		[string]$Name,
		[int]$RetentionDays
	);
	
	$jobName = "$Name - Cleanup Older Files";
	$task = Get-ScheduledTask -TaskName $jobName -ErrorAction SilentlyContinue;
	
	if ($task -eq $null) {
		$trigger = New-ScheduledTaskTrigger -At 2am -Daily;
		$runAsUser = "NT AUTHORITY\SYSTEM";
		$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5);
		
		$action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-ExecutionPolicy BYPASS -NonInteractive -NoProfile -File C:\PerfLogs\Remove-OldCollectorSetFiles.ps1 -Name $Name -RetentionDays $RetentionDays ";
		$task = Register-ScheduledTask -TaskName $jobName -Trigger $trigger -Action $action -User $runAsUser -Settings $settings -RunLevel Highest -Description "Regular cleanup of Data Collector Set files (> 45 days old) for `"$Name`" Data Collecctor.";
	}
	
}