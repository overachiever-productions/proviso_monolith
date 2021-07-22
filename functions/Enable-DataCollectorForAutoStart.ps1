## Implementation of work-around listed here: https://docs.microsoft.com/en-us/troubleshoot/windows-server/performance/user-defined-dcs-doesnt-run-as-scheduled

Set-StrictMode -Version 1.0;

function Enable-DataCollectorForAutoStart {
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$Name
	);
	
	## assumes same convention used by Data Collector Setup - i.e., a task with the name of the data collector will be found in the \Microsoft\Windows\PLA\ folder. 
	$task = Get-ScheduledTask -TaskName $Name -TaskPath "\Microsoft\Windows\PLA\";
	
	$newAction = New-ScheduledTaskAction -Execute "C:\windows\system32\rundll32.exe" -Argument "C:\windows\system32\pla.dll,PlaHost `"$Name`" `"`$(Arg0)`"";
	$trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay 00:00:05;
	
	Set-ScheduledTask -TaskName $Name -TaskPath "\Microsoft\Windows\PLA\" -Action $newAction -Trigger $trigger | Out-Null;
}