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

filter Get-WindowsServerVersion {
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

filter Get-ResumeFromRestartScript {
	param (
		[Parameter(Mandatory)]
		[string]$Identifier,
		[Parameter(Mandatory)]
		[string]$RunbookOperation
	);
	
	
	[string]$template = 'Set-StrictMode -Version 1.0;

try {{

	Import-Module -Name Proviso -DisableNameChecking;
	$PVContext.WriteLog("Initiating Resume-Once Script: [{0}].", "Debug");

		Map -ProvisoRoot "{1}";
		Target -CurrentHost;

		$results = ({2} -AllowSqlRestart) | Out-File -FilePath "C:\Scripts\results_{0}.txt";

	$PVContext.WriteLog("Operations for Resume-Once Script [{0}] are complete.", "Debug");
}}
catch {{
	$content = "EXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	$PVContext.WriteLog("Operations for Resume-Once Script [{0}] Failed with: $content.", "Critical");
}}
';
	
	$currentRoot = $PVResources.ProvisoRoot;
	$output = [string]::Format($template, $Identifier, $currentRoot, $RunbookOperation);
	
	return $output;
}

filter Restart-Server {
	param (
		[string]$RestartRunbookTarget = $null,
		[int]$WaitSeconds = 0,
		[switch]$PreserveDomainCreds = $false   # TODO: look at a way to serialize these... (safely) and so on... 
		#[switch]$DoNotTemporarilyPreserveDomainCredsToFile = $true # i.e., don't allow them to be temporarily stored...  ALSO: REFACTOR...
	);
		
	if ($WaitSeconds -gt 0) {
		$PVContext.WriteLog("Reboot Initialized - will execute in $WaitSeconds Seconds.", "IMPORTANT");
	}
	
	Start-Sleep -Seconds $WaitSeconds;
	
	# https://stackoverflow.com/questions/13965997/powershell-set-a-scheduled-task-to-run-when-user-isnt-logged-in/70793765#70793765
	if ($RestartRunbookTarget) {
		
		$identifier = "$([guid]::NewGuid())".Substring(0, 8);
		$scriptContents = Get-ResumeFromRestartScript -Identifier $identifier -RunbookOperation $RestartRunbookTarget;
		$filePath = "C:\Scripts\resume_once_$identifier.ps1";
		Set-Content -Path $filePath -Value $scriptContents;
		
		$PVContext.WriteLog("Resume_Once File Created at: $filePath", "Debug");
		
		# now, create a scheduled task that'll run the $filePath via the CURRENT runtime (PowerShell) upon server startup... 
		$executatablePath = Join-Path -Path $PSHOME -ChildPath "pwsh.exe";
		
		$jobName = "Proviso - Resume Once";
		$existingJob = Get-ScheduledTask -TaskName $jobName -ErrorAction SilentlyContinue;
		if ($existingJob) {
			Unregister-ScheduledTask -TaskName $jobName -Confirm:$false | Out-Null;
		}
		
		$trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay (New-TimeSpan -Seconds 30);
		$settings = New-ScheduledTaskSettingsSet -DisallowDemandStart -MultipleInstances IgnoreNew;
		
		# Work-Around for Auto-Cleanup of Jobs, as per: https://iamsupergeek.com/self-deleting-scheduled-task-via-powershell/
		$settings.DeleteExpiredTaskAfter = "PT0S";
		$trigger.StartBoundary = (Get-Date).ToString("yyyy-MM-dd'T'HH:mm:ss");
		$trigger.EndBoundary = (Get-Date).AddMinutes(50).ToString("yyyy-MM-dd'T'HH:mm:ss");
		
		$arguments = "-ExecutionPolicy BYPASS -NoProfile -File `"$($filePath)`" ";
		
		$user = $PVDomainCreds.RebootCredentials.UserName;
		$pass = $PVDomainCreds.RebootCredentials.GetNetworkCredential().Password;
		
		$action = New-ScheduledTaskAction -Execute $executatablePath -Argument $arguments;
		Register-ScheduledTask -TaskName $jobName -Trigger $trigger -Action $action -Settings $settings -User $user -Password $pass -RunLevel Highest -Description "Resumable Proviso Workflow following Server Reboot." | Out-Null;
		
		$PVContext.WriteLog("Executing Server Reboot - With Resume-Once Configured.", "Debug");
	}
	else {
		$PVContext.WriteLog("Executing Server Reboot.", "Debug");
	}
	
	shutdown /f /r /t 00;
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

filter Validate-WindowsCredentials {
	param (
		[Parameter(Mandatory)]
		[PSCredential]$Credentials
	);
	
	if ("WORKGROUP" -eq ((Get-CimInstance Win32_ComputerSystem).Domain)) {
		return Test-LocalAuthorityCredentials -LocalCreds $Credentials;
	}
	
	return Test-DomainCredentials -DomainCreds $Credentials;
}

filter Test-LocalAuthorityCredentials {
	param (
		[Parameter(Mandatory)]
		[PSCredential]$LocalCreds
	);
	
	try {
		$username = $LocalCreds.UserName;
		$password = $LocalCreds.GetNetworkCredential().Password;

		Add-Type -AssemblyName System.DirectoryServices.AccountManagement;
		$type = [DirectoryServices.AccountManagement.ContextType]::Machine;
		$PrincipalContext = [DirectoryServices.AccountManagement.PrincipalContext]::new($type);
		$PrincipalContext.ValidateCredentials($UserName, $Password);
	}
	catch {
		return $false;
	}
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
