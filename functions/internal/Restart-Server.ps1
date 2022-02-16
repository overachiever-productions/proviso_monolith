Set-StrictMode -Version 1.0;

function Restart-Server {
	param (
		[string]$RestartRunbookTarget = $null,
		[int]$WaitSeconds = 0,
		[switch]$DoNotTemporarilyPreserveDomainCredsToFile = $true # i.e., don't allow them to be temporarily stored...  ALSO: REFACTOR...
	);
	
	# if there's a target... 
	#  1. serialize a bunch of stuff for preservation of state for startup job. 
	# 		such as: 
	# 			-ProvisoRoot
	# 			-TargetHostName 
	# 			-SerializedSecrets/Creds. 
	# 			-TemporarilySerializedDomainCreds IF allowed. 
	
	#  2. Create a job that'll take in either 
	# 			a. args for the above, serialized details 
	# 			b. the directive to call a 1x-only-executed function... which'll 'hard-code' the above details to some temp files... 
	# 					e.g., the TaskScheduler task could be something simple like: PowerShell 7.exe "C:\Scripts\proviso_restart_<timestamp_here>.ps1"
	# 				and then when that func starts up... it'll rehydrate details, then NUKE/DROP the intermediate state... 
	# 				Yeah, option B... 
	# 			c. once everything is rehydrated and cleaned-up... 
	# 				then, <verb>-<runbook> as directed. 
	
	Start-Sleep -Seconds $WaitSeconds;
	
	# 'simulated' implementation of the above: 
	if ($RestartRunbookTarget) {
		Write-Host "!!!!!!!!!!!!!!!!!!! 	SIMULATED REBOOT --- HAPPENING RIGHT NOW 		!!!!!!!!!!!!!!!!!!!";
		Write-Host "			!!!!!!! 	REBOOT JOB WILL TARGET: [$RestartRunbookTarget]		!!!!!! ";
	}
	else {
		Write-Host "!!!!!!!!!!!!!!!!!!! 	SIMULATED REBOOT --- HAPPENING RIGHT NOW 	!!!!!!!!!!!!!!!!!!!";
	}
}