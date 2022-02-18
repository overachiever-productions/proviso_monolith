Set-StrictMode -Version 1.0;

filter ConvertTo-WindowsSecurityIdentifier {
	<# 
		I MAY end up needing to be able to pull SIDs out of AD. 
		If so, the approach to adding AD into Windows Server (works on posh5 and posh7) is: 
			> Add-WindowsFeature RSAT-AD-PowerShell
					See: https://stackoverflow.com/a/17548616/11191
		(might need a reboot - so keep an eye on that). 

		Otherwise, once that's done, I can do: 
			> Get-ADUser "OVERACHIEVER\sqlservice" or whatever and ... golden. 

	#>	
	param (
		[Parameter(Mandatory)]
		[string]$Name
	);
	
	$ntObject = New-Object System.Security.Principal.NTAccount($Name) -ErrorAction SilentlyContinue;
	if ($null -eq $ntObject) {
		return $null;
	}
	
	try {
		$sid = $ntObject.Translate([System.Security.Principal.SecurityIdentifier]);
		return $sid;
	}
	catch {
		return $null;
	}
}

filter Get-WindowsCoreCount {
	(Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
}

function Get-WindowsServerVersion {
	<#
			# https://en.wikipedia.org/wiki/List_of_Microsoft_Windows_versions#Server_versions
			# https://www.techthoughts.info/windows-version-numbers/

	#>	
	param (
		[System.Version]$Version = [System.Environment]::OSVersion.Version
	)
	
	if ($Version.Major -eq 10) {
		if ($Version.Build -ge 17763) {
			return "Windows2019";
		}
		else {
			return "Windows2016";
		}
		
		#$output = $Version.Build -ge 17763 ? "Windows2019" : "Windows2016";
	}
	
	if ($Version.Major -eq 6) {
		switch ($Version.Minor) {
			0 {
				return "Windows2008";
			}
			1 {
				return "Windows2008R2";
			}
			2 {
				return "Windows2012";
			}
			3 {
				return "Windows2012R2";
			}
			default {
				return "UNKNOWN"
			}
		}
	}
}

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