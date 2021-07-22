Set-StrictMode -Version 1.0;

function Restart-ServerAndResumeProviso {
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$ProvisoRoot,
		[string]$ProvisoConfigPath = $null,
		[Parameter(Mandatory = $true)]
		[string]$WorkflowFile,
		[string]$ServerName,
		[switch]$PreservePSVersion = $true,
		[switch]$Force = $false
	);
	
	try {
		
		if ([string]::IsNullOrEmpty($ProvisoRoot)) { 
			throw "Parameter `$ProvisoRoot is REQUIRED when configuring resumable-operations.";
		}
		
		if (-not ($Force)) {
			throw "Resumable restart requires the `$Force switch. ";
		}
		
		Mount-Directory -Path "C:\Scripts";
		
		if ([string]::IsNullOrEmpty($ProvisoConfigPath)) {
			$content = "@{`r`tResourcesRoot = `"$($ProvisoRoot)`"`r}";
			New-Item "C:\Scripts\proviso.config.psd1" -Value $content -Force | Out-Null;
		}
		else {
			if (-not (Test-Path -Path $ProvisoConfigPath)) {
				throw "Invalid Path specified for `$ProvisoConfigPath.";
			}
			
			# copy to C:\Scripts if/as needed: 
			$file = Split-Path -Path $ProvisoConfigPath -Leaf;
			$parent = Split-Path -Path $ProvisoConfigPath -Parent;
			
			if ($parent -ne "C:\Scripts") {
				$scriptsConfig = Join-Path -Path "C:\Scripts" -ChildPath $file;
				Copy-Item $ProvisoConfigPath -Destination $scriptsConfig -Force | Out-Null;
			}
		}
		
		if (-not (Test-Path -Path $WorkflowFile)) {
			throw "Invalid Path / File Specified for Resumable Workflow Following Restart; Invalid Path for `$WorkflowFile. ";
		}
		
		$child = Split-Path -Path $WorkflowFile -Leaf;
		$parent = Split-Path -Path $WorkflowFile -Parent;
		
		if ($parent -ne "C:\Scripts") {
			$resumableWorkflowFile = Join-Path -Path "C:\Scripts" -ChildPath $child;
			Copy-Item $WorkflowFile -Destination $resumableWorkflowFile -Force | Out-Null;
		}
		
		# Create a Job for Startup:
		$jobName = "Proviso - Workflow Restart";
		$existingJob = Get-ScheduledTask -TaskName $jobName -ErrorAction SilentlyContinue;
		if ($existingJob -ne $null) {
			Unregister-ScheduledTask -TaskName $jobName -Confirm:$false | Out-Null;
		}
		
		$trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay (New-TimeSpan -Seconds 30);
		$runAsUser = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest;
		$settings = New-ScheduledTaskSettingsSet -DisallowDemandStart -MultipleInstances IgnoreNew;

		# NOTE: Bug-fix/work-around as outlined here for cleanup of previously processed tasks: https://iamsupergeek.com/self-deleting-scheduled-task-via-powershell/
		$settings.DeleteExpiredTaskAfter = "PT0S";
		$trigger.StartBoundary = (Get-Date).ToString("yyyy-MM-dd'T'HH:mm:ss");
		$trigger.EndBoundary = (Get-Date).AddMinutes(50).ToString("yyyy-MM-dd'T'HH:mm:ss"); # in SOME environments this may require a reboot before the job is removed. on 2019 the job disappears after N minutes (if not running))
		
		$arguments = "-ExecutionPolicy BYPASS -NonInteractive -NoProfile -File `"$($resumableWorkflowFile)`" ";
		if (-not ([string]::IsNullOrEmpty($ServerName))) {
			$arguments += " -targetMachine $ServerName  ";
		}
		
		$executable = "Powershell.exe";
		if ($PreservePSVersion) {
			$executable = Get-VersionedPowershellExecutionPath; 
		}
		
		$action = New-ScheduledTaskAction -Execute $executable -Argument $arguments;
		
		Register-ScheduledTask -TaskName $jobName -Trigger $trigger -Action $action -Settings $settings -User "Administrator" -Password "Pass@word1" -RunLevel Highest -Description "Resumable Proviso Workflow following Server Reboot." | Out-Null;
	}
	catch {
		Write-Host "Exception: $_";
		Write-Host "`t$($_.ScriptStackTrace)";
	}
	
	Restart-Computer -Force -Confirm:$false | Out-Null;
}