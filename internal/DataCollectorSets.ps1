﻿Set-StrictMode -Version 1.0;

# TODO: 
# 		Add a method that cleans up ALL Proviso "xyz clenaup jobs in the task scheduler."


filter Get-DataCollectorSetStatus {
	param (
		[string]$Name
	);
	
	try {
		# Sadly, this is total BS: https://docs.microsoft.com/en-us/powershell/scripting/whats-new/module-compatibility?view=powershell-7.1 
		#$state = Get-SMPerformanceCollector -CollectorName $Name -ErrorAction Stop;
		
		$query = logman query "$Name";
		if ($query -like "Data Collector Set was not found.") {
			return "<EMPTY>";
		}
		
		$regex = New-Object System.Text.RegularExpressions.Regex("Status:\s+(?<status>[^\r]+){1}", [System.Text.RegularExpressions.RegexOptions]::Multiline);
		$matches = $regex.Match($query);
		$status = "<EMPTY>";
		if ($matches) {
			$hack = $matches.Groups[1].Value;
			# not sure why... and... don't care at this point ... but instead of getting "Running" as the named capture... I'm getting EVERYTHING from "running" to the END of the stupid text... 
			#  I've tried multi-line, single-line, etc. ... 
			# so... this is a hack and ... meh. 
			$status = $hack.Substring(0, $hack.IndexOf(" ")).Trim();
		}
		
		return $status;
	}
	catch {
		$state = "<EMPTY>";
	}
	
	return $state;
}

filter New-DataCollectorSetFromConfigFile {
	param (
		[string]$Name,
		[string]$ConfigFilePath
	);
	
	$status = Get-DataCollectorSetStatus $Name;
	
	if ($status -ne "<EMPTY>") {
		if ($status -eq "Running") {
			Invoke-Expression "logman.exe stop `"$Name`"" | Out-Null;
		}
		
		Invoke-Expression "logman.exe delete `"$Name`"" | Out-Null;
	}
	
	Invoke-Expression "logman.exe import `"$Name`" -xml `"$ConfigFilePath`"" | Out-Null;
}

filter Start-DataCollector {
	param (
		[string]$Name
	);
	
	$status = Get-DataCollectorSetStatus -Name $Name;
	if ("Running" -ne $status) {
		$results = Invoke-Expression "logman.exe start `"$Name`"";
		if ("The command completed successfully." -ne $results) {
			throw "Error STARTING Data Collector Set [$Name]: $results";
		}
	}
}

filter Stop-DataCollector {
	param (
		[string]$Name,
		[string]$ConfigFilePath
	);
	
	$status = Get-DataCollectorSetStatus -Name $Name;
	if ("Stopped" -ne $status) {
		$results = Invoke-Expression "logman.exe stop `"$Name`"";
		if ("The command completed successfully." -ne $results) {
			throw "Error STOPPING Data Collector Set [$Name]: $results";
		}
	}
}

filter Enable-DataCollectorSetForAutoStart {
	param (
		[Parameter(Mandatory)]
		[string]$Name,
		[switch]$Disable
	);
	
	if ($Disable) {
		throw "Proviso Framework Error. Disabling DataCollectorSets for AutoStart (with OS) is not YET supported.";
	}
	
	## assumes same convention used by Data Collector Setup - i.e., a task with the name of the data collector will be found in the \Microsoft\Windows\PLA\ folder. 
	$task = Get-ScheduledTask -TaskName $Name -TaskPath "\Microsoft\Windows\PLA\";
	$trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay 00:00:05;
	
	if ((Get-WindowsServerVersion) -eq "Windows2019") {
		## Implementation of work-around listed here: https://docs.microsoft.com/en-us/troubleshoot/windows-server/performance/user-defined-dcs-doesnt-run-as-scheduled
		$newAction = New-ScheduledTaskAction -Execute "C:\windows\system32\rundll32.exe" -Argument "C:\windows\system32\pla.dll,PlaHost `"$Name`" `"`$(Arg0)`"";
		
		Set-ScheduledTask -TaskName $Name -TaskPath "\Microsoft\Windows\PLA\" -Action $newAction -Trigger $trigger | Out-Null;
	}
	else {
		Set-ScheduledTask -TaskName $Name -TaskPath "\Microsoft\Windows\PLA\" -Trigger $trigger | Out-Null;
	}
}

filter New-DataCollectorSetFileCleanupJob {
	param (
		[Parameter(Mandatory)]
		[string]$Name,
		[Parameter(Mandatory)]
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

# TODO: turn this into a FUNC (not filter), allow it to be called per MULTIPLE data-collector sets 
# 		e.g., 
# 				> $targets = @("Consolidated","Mirroring","BatchStats", "Etc");
# 				> Remove-OldDataCollectorFiles $DataCollectorName $targets 45;
#		THEN, set up 'New-DataCollectorSetFileCleanupJob' to allow 1 or more targets ... i.e., create if NO targets, CHANGE if already 1 target/etc. 
# 		in short: don't have N cleanup jobs ... have 1 instead.
filter Remove-OldDataCollectorFiles {
	param (
		[Parameter(Mandatory)]
		[string]$DataCollectorName,
		[int]$DaysWorthOfLogsToKeep = 45,
		[string]$RootFilePath = "C:\PerfLogs\"
	);
	
	$threshold = (Get-Date).AddDays(0 - $DaysWorthOfLogsToKeep);
	$directory = Join-Path -Path $RootFilePath -ChildPath $DataCollectorName;
	
	Get-ChildItem $directory | Where-Object CreationTime -lt $threshold | Remove-Item -Force;
}