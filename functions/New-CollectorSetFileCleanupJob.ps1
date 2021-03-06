## vNEXT: optionally compress the target data-collector-file (storage) directory: 
##    fodder: 
## 			https://serverfault.com/questions/977673/how-to-enable-ntfs-folder-compression-on-windows-server-core
## 			https://serverfault.com/questions/773696/how-can-i-use-powershell-to-enable-ntfs-compression-in-place-on-log-files-olde


Set-StrictMode -Version 1.0;

function New-CollectorSetFileCleanupJob {
	
	$trigger = New-ScheduledTaskTrigger -At 2am -Daily;
	$runAsUser = "NT AUTHORITY\SYSTEM";
	$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5);
	
	$action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-ExecutionPolicy BYPASS -NonInteractive -NoProfile -File C:\PerfLogs\Remove-OldCollectorSetFiles.ps1";
	
	$task = Register-ScheduledTask -TaskName "Consolidated - Cleanup Older Files" -Trigger $trigger -Action $action -User $runAsUser -Settings $settings -RunLevel Highest -Description "Regular cleanup of Data Collector Set files (> 45 days old) for `"Consolidated`" Data Collecctor.";
}