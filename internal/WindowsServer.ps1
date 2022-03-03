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

filter Restart-Server {
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
	
	if ($WaitSeconds -gt 0) {
		$PVContext.WriteLog("Reboot Initialized - will execute in $WaitSeconds Seconds.", "IMPORTANT");
	}
	
	
	Start-Sleep -Seconds $WaitSeconds;
	
	# 'simulated' implementation of the above: 
	if ($RestartRunbookTarget) {
		Write-Host "!!!!!!!!!!!!!!!!!!! 	SIMULATED REBOOT --- HAPPENING RIGHT NOW 		!!!!!!!!!!!!!!!!!!!";
		Write-Host "			!!!!!!! 	REBOOT JOB WILL TARGET: [$RestartRunbookTarget]		!!!!!! ";
	}
	else {
		$PVContext.WriteLog("Executing Server Reboot.", "Debug");
		shutdown /f /r /t 00;
	}
}

filter Install-NetFx35ForPre2016Instances {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet("Windows2012R2", "Windows2016", "Windows2019")]
		[string]$WindowsServerVersion,
		[Parameter(Mandatory)]
		[string]$NetFxSxsRootPath
	);
	
	$binariesPath = Join-Path -Path $NetFxSxsRootPath -ChildPath $WindowsServerVersion;
	
	$installed = (Get-WindowsFeature Net-Framework-Core).InstallState;
	
	if ($installed -ne "Installed") {
		Install-WindowsFeature Net-Framework-Core -source $binariesPath
	}
}

filter Install-WsfcComponents {
	# Fodder: https://docs.microsoft.com/en-us/powershell/module/failoverclusters/?view=windowsserver2019-ps
	$rebootRequired = $false;
	$processingError = $null;
	
	$installed = (Get-WindowsFeature -Name Failover-Clustering).InstallState;
	switch ($installed) {
		"Installed" {
			$PVContext.WriteLog("WSFC Components already installed.", "Debug");
		}
		"InstallPending" {
			$PVContext.WriteLog("Windows Feature 'Failover-Clustering' is in InstallPending state - i.e., installed by machine requires restart.", "Important");
			$rebootRequired = $true;
		}
		"Available" {
			try {
				Install-WindowsFeature Failover-Clustering -IncludeManagementTools -ErrorVariable processingError | Out-Null;
				
				if ($null -ne $processingError) {
					throw "Fatal error installing WSFC Components: $processingError ";
				}
			}
			catch {
				throw "Fatal Exception Encountered during installation of WSFC Components: $_ `r`t$($_.ScriptStackTrace)";
			}
			
			if ($null -eq $processingError) {
				$rebootRequired = $true;
			}
		}
		default {
			throw "WindowsFeature 'Failover-Clustering' is in an unexpected state: $installed. Terminating Proviso Execution.";
		}
	}
	
	$powershellInstalled = (Get-WindowsFeature -Name RSAT-Clustering-PowerShell).InstallState;
	if ($powershellInstalled -ne "Installed") {
		Install-WindowsFeature RSAT-Clustering-PowerShell -IncludeAllSubFeature | Out-Null;
		$rebootRequired = $true;
	}
	
	return $rebootRequired;
}

filter Test-DomainCredentials {
	param (
		[Parameter(Mandatory)]
		[PSCredential]$DomainCreds
	);
	
	try {
		$username = $DomainCreds.UserName;
		$password = $DomainCreds.GetNetworkCredential().Password;
		
		$CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName;
		$test = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain, $username, $password);
		
		return ($null -ne $test);
	}
	catch {
		return $false;
	}
}

filter Grant-PermissionsToDirectory {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$TargetDirectory,
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Account
	);
	
	$acl = Get-Acl $TargetDirectory;
	$rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule($Account, "FullControl", "ContainerInherit,Objectinherit", "none", "Allow");
	
	$acl.SetAccessRule($rule);
	Set-Acl -Path $TargetDirectory -AclObject $acl;
}