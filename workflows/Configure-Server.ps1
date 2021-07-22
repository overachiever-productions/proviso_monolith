﻿#Requires -RunAsAdministrator
param (
	$targetMachine = $null
);

Set-StrictMode -Version 1.0;

#region boostrap
function Find-Config {
	[string[]]$locations = (Split-Path -Parent $PSCommandPath), "C:\Scripts";
	[string[]]$extensions = ".psd1", ".config", ".config.psd1";
	
	foreach ($location in $locations) {
		foreach ($ext in $extensions) {
			$path = Join-Path -Path $location -ChildPath "proviso$($ext)";
			if (Test-Path -Path $path) {
				return $path;
			}
		}
	}
}

function Request-Value {
	param (
		[string]$Message,
		[string]$Default
	);
	
	if (-not ($output = Read-Host ($Message -f $Default))) {
		$output = $Default
	}
	
	return $output;
}

function Verify-ProvosioRoot {
	param (
		[string]$Directory
	);
	
	if (-not (Test-Path $Directory)) {
		return $null;
	}
	
	[string[]]$subdirs = "assets", "binaries", "definitions", "repository";
	
	foreach ($dir in $subdirs) {
		if (-not (Test-Path -Path (Join-Path -Path $Directory -ChildPath $dir))) {
			return $null;
		}
	}
	
	return $Directory;
}

function Load-Proviso {
	$exists = Get-PSRepository | Where-Object {
		$_.Name -eq "ProvisoRepo"
	};
	if ($exists -eq $null) {
		$path = Join-Path -Path $script:resourcesRoot -ChildPath "repository";
		Register-PSRepository -Name ProvisoRepo -SourceLocation $path -InstallationPolicy Trusted;
	}
	
	Write-Log "Proviso Exists: $exists ";
	
	$nuget = Get-PackageProvider -Name Nuget;
	Write-Log "`rNuget: $nuget "
	
	return;
	
	Install-Module -Name Proviso -Repository ProvisoRepo -Confirm:$false -Force;
	# Grrr... the ABOVE is throwing the following 'prompts' when run interactively... no idea why either ... i.e., interactive = running as ADMINISTRATOR, non-interactive = running as Administrator as well... there's NO DIFFERENCE.
	#    	and... infuriatingly enough... i don't get ANY prompts when running in interactive mode... 
	#    so... this HAS to be something to do with some sort of 'difference' in the various versions of NuGet providers stuff... 
	
	# InstallNuGetProviderShouldContinueCaption=NuGet provider is required to continue 
	# InstallNuGetProviderShouldContinueQuery=PowerShellGet requires NuGet provider version '{0}' or newer to interact with NuGet-based repositories. The NuGet provider must be available in '{1}' or '{2}'. You can also install the NuGet provider by running 'Install-PackageProvider -Name NuGet -MinimumVersion {0} -Force'. Do you want PowerShellGet to install and import the NuGet provider now?
	
	
	Import-Module -Name Proviso -Force;
	
	Write-Log "Proviso Install Complete... ";
}

function Verify-MachineConfig {
	param (
		[string]$ConfigPath
	);
	
	if (-not (Test-Path -Path $ConfigPath)) {
		return $null;
	}
	
	$testConfig = Read-ServerDefinitions -Path $ConfigPath -Strict:$false;
	
	if ($testConfig.NetworkDefinitions -ne $null -or $testConfig.TargetServer -ne $null) {
		return $ConfigPath;
	}
}

function Write-Log {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Message
	);
	
	# TODO: if proviso.config.psd1 says to log... then log, otherwise, don't. 
	#  which also means... cache some of this info or whatever... 
	#   also... MAYBE have a bootstrap_log.txt vs a workflow_log.tx as well? 
	
	
	# TODO: also? maybe create a Write-Output function that ... 
	#   a. determines if we're  in interactive or not... 
	#   b. if we are... sends this stuff to WRite-Host and ... 
	#   c. if we're not, sends this stuff OUT to a file IF it's been correctly configured in the  .config
	
	$script:log_initialized = $false;
	
	[string]$loggingPath = "C:\Scripts\workflowed.txt";
	
	if (-not ($script:log_initialized)) {
		if (Test-Path -Path $loggingPath) {
			Remove-Item -Path $loggingPath -Force;
		}
		
		New-Item $loggingPath -Value $Message -Force | Out-Null;
		
		$script:log_initialized = $true;
	}
	else {
		Add-Content $loggingPath $Message;
	}
}

try {
	# silently disable any scheduled tasks PREVIOUSLY created by proviso: 
	Disable-ScheduledTask -TaskName "Proviso - Workflow Restart" -ErrorAction SilentlyContinue | Out-Null;
	
	$script:configPath = Find-Config;
	$pRoot = $null;
	if (-not ([string]::IsNullOrEmpty($script:configPath))) {
		$pRoot = (Import-PowerShellDataFile -Path $script:configPath).ResourcesRoot;
		$pRoot = Verify-ProvosioRoot -Directory $pRoot;
	}
	
	if ([string]::IsNullOrEmpty($pRoot)) {
		$pRoot = Verify-ProvosioRoot -Directory "C:\Scripts";
		if ([string]::IsNullOrEmpty($pRoot)) {
			$pRoot = Verify-ProvosioRoot -Directory "C:\Scripts\proviso";
		}
	}
	
	if ([string]::IsNullOrEmpty($pRoot)) {
		$pRoot = Request-Value -Message "Please specify location of Proviso Resources folder - e.g., \\file-server\builds\proviso\etc`n";
		$pRoot = Verify-ProvosioRoot -Directory $pRoot.Replace("`"", "");
	}
	
	if ([string]::IsNullOrEmpty($pRoot)) {
		throw "Invalid Proviso Resources-Root Directory Specified. Please check proviso.config.psd1 and/or input of response to previous request. Terminating...";
	}
	
	$who = $(whoami)
	Write-Log "Executing as $who ";
	Write-Log "Starting Process of Loading Proviso... ";
	Load-Proviso;
	
	try {
		Write-Log "MachineNameFromArgs: $targetMachine ";
		Write-Log "ComputerNameFromEnv: $($env:COMPUTERNAME) ";
		$matches = Find-MachineDefinition -RootDirectory (Join-Path -Path $script:resourcesRoot -ChildPath "definitions\servers") -MachineName ($env:COMPUTERNAME);
		
	}
	catch {
		Write-Log "Exception: $_ ";
	}
	
	if ($matches.Count -eq 0) {
		if (-not ($targetMachine -eq $null)) {
			$machineName = $targetMachine;
			Write-Host "Looking for config file for target machine: $machineName ... ";
		}
		else {
			$machineName = Request-Value -Message "Please specify name of Target VM to provision - e.g., `"SQL-97`".`n" -Default $null;
		}
		$matches = Find-MachineDefinition -RootDirectory (Join-Path -Path $script:resourcesRoot -ChildPath "definitions\servers") -MachineName $machineName;
	}
	
	$mFile = $null;
	switch ($matches.Count) {
		0 {
			# nothing... $mFile stays $null... 
		}
		1 {
			$mFile = $matches[0].Name;
		}
		default {
			Write-Host "Multiple Target-Machine files detected:";
			$i = 0;
			foreach ($m in $matches) {
				Write-Host "`t$([char]($i + 65)). $($m.Name) - $([System.Math]::Round($m.Size, 2))KB - ($([string]::Format("{0:yyyy-MM-dd}", $m.Modified)))";
				$i++;
			}
			Write-Host "`tX. Exit or terminate processing.`n";
			Write-Host "Please Specify which Target-Machine file to use - e.g., enter the letter A or B (or X to terminate)`n";
			[char]$fileOption = Read-Host;
			
			if (([string]::IsNullOrEmpty($fileOption)) -or ($fileOption -eq "X")) {
				Write-Host "Terminating...";
				return;
			}
			$x = [int]$fileOption - 65;
			$mFile = $matches[$x].Name;
		}
	}
	
	$mFile = Verify-MachineConfig -ConfigPath $mFile;
	
	if ($mFile -eq $null) {
		throw "Missing or Invalid Target-Machine-Name Specified. Please verify that a '<Machine-Name.psd1>' or '<Machine-Name>.config' file exists in the Resources-Root\definitions directory.";
	}
	
	Write-Log "Bootstrapping completed...";
	
	$script:targetMachineFile = $mFile;
}
catch {
	Write-Host "Exception: $_";
	Write-Host "`t$($_.ScriptStackTrace)";
	
	Write-Log "EXCEPTION: $_  `r$($_.ScriptStackTrace) ";
}
#endregion 

#region core-workflow
try {
	$script:adminDbInstalled = $false;
	
	[PSCustomObject]$serverDefinition = Read-ServerDefinitions -Path $script:targetMachineFile -Strict;
	
	# Tackle OS Preferences First: 
	$dvdDrive = (Get-ConfigValue -Definition $serverDefinition -Key "WindowsPreferences.DvdDriveToZ" -Default $false) ? "Z": $null;
	$optimizeExplorer = Get-ConfigValue -Definition $serverDefinition -Key "WindowsPreferences.OptimizeExplorer" -Default $true;
	$disableServerManager = Get-ConfigValue -Definition $serverDefinition -Key "WindowsPreferences.DisableServerManagerOnLaunch" -Default $true;
	$diskCounters = Get-ConfigValue -Definition $serverDefinition -Key "WindowsPreferences.EnableDiskPerfCounters" -Default $true;
	$highPerf = Get-ConfigValue -Definition $serverDefinition -Key "WindowsPreferences.SetPowerConfigHigh" -Default $true;
	$disableMonitorTimeout = Get-ConfigValue -Definition $serverDefinition -Key "WindowsPreferences.DisableMonitorTimeout" -Default $true;
	
	Set-WindowsServerPreferences `
		 -TargetVolumeForDvdDrive $dvdDrive `
		 -SetWindowsExplorerPreferences:$optimizeExplorer `
		 -DisableServerManager:$disableServerManager `
		 -EnableDiskPerfCounters:$diskCounters `
		 -SetPowerConfigToHighPerf:$highPerf `
		 -DisableMonitorTimeout:$disableMonitorTimeout `
		 -Force;
	
	if ((Get-ConfigValue -Definition $serverDefinition -Key "LimitHostTls1dot2Only" -Default $false)) {
		Limit-HostTls12Only;
	}
	
	# Required Packages
	if ((Get-ConfigValue -Definition $serverDefinition -Key "RequiredPackages" -Default $null) -ne $null) {
		if ((Get-ConfigValue -Definition $serverDefinition -Key "RequiredPackages.WsfcComponents" -Default $false)) {
			Install-WsfcComponents;
		}
		
		if ((Get-ConfigValue -Definition $serverDefinition -Key "RequiredPackages.NetFxForPre2016InstancesRequired" -Default $false)) {
			$windowsVersion = Get-WindowsVersion -Version ([System.Environment]::OSVersion.Version);
			Install-NetFx35ForPre2016Instances -WindowsServerVersion $windowsVersion -NetFxSxsRootPath (Join-Path -Path $script:resourcesRoot -ChildPath "binaries\net3.5_sxs");
		}
	}
	
	# Firewall Rules: 
	if ((Get-ConfigValue -Definition $serverDefinition -Key "FirewallRules.EnableFirewallForSqlServer" -Default $false)) {
		$enableDAC = Get-ConfigValue -Definition $serverDefinition -Key "FirewallRules.EnableFirewallForSqlServerDAC" -Default $false;
		$enableMirroring = Get-ConfigValue -Definition $serverDefinition -Key "FirewallRules.EnableFirewallForSqlServerMirroring" -Default $false;
		
		Unblock-FirewallForSqlServer -EnableDAC:$enableDAC -EnableMirroring:$enableMirroring -Silent;
	}
	if ((Get-ConfigValue -Definition $serverDefinition -Key "FirewallRules.EnableICMP" -Default $false)) {
		Enable-Icmp -Silent;
	}
	
	# Disks:
	$definedVolumesAlreadyOnServer = Get-ExistingVolumeLetters;
	Initialize-DefinedDisks -ServerDefinition $serverDefinition -CurrentlyMountedVolumes $definedVolumesAlreadyOnServer -ProcessEphemeralDisksOnly:$false -Strict;
	
	# SQL Server Installation:
	$dataDirectory = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation.SqlServerDefaultDirectories.SqlDataPath" -Default "D:\SQLData";
	$backupDirectory = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation.SqlServerDefaultDirectories.SqlBackupsPath" -Default "D:\SQLBackups";
	
	$installSqlDataDir = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation.SqlServerDefaultDirectories.InstallSqlDataDir" -Default $dataDirectory; 
	$logsDirectory = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation.SqlServerDefaultDirectories.SqlLogsPath" -Default $dataDirectory; 
	$tempdbDirectory = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation.SqlServerDefaultDirectories.TempDbPath" -Default $dataDirectory; 
	
	$sqlDirectories = @{
		SqlDataPath	      = $dataDirectory
		SqlBackupsPath    = $backupDirectory
		InstallSqlDataDir = $installSqlDataDir
		SqlLogsPath	      = $logsDirectory
		TempDbPath	      = $tempdbDirectory
	}
	
	foreach ($key in $sqlDirectories.Keys) {
		$dir = $sqlDirectories.Item($key);
		
		if ([string]::IsNullOrEmpty($dir)) {
			throw "Missing SQL Server Data Directory for $key. Values for SqlDataPath and SQLBackupPath must be defined in .psd1. Terminating.";
		}
		
		Mount-Directory -Path $dir;
	}
	
	$installedInstances = Get-InstalledSqlServerInstanceNames;
	
	# Define Installation Settings:
	# vNEXT: neither of these allow for easy overrides of convention... Or, actually: neither of these allow for ANY overrides of convention.
	$sqlInstallPath = Find-SqlSetupExe -RootDirectory (Join-Path -Path $script:resourcesRoot -ChildPath "binaries\sqlserver") -SetupKey ($serverDefinition.SqlServerInstallation.SqlExePath);
	$sqlConfigFile = Find-SqlIniFile -RootDirectory (Join-Path -Path $script:resourcesRoot -ChildPath "definitions\sql") -IniKey ($serverDefinition.SqlServerInstallation.SqlIniFile);
	
	if ($sqlInstallPath -eq $null -or $sqlConfigFile -eq $null) {
		throw "Invalid or Missing SqlExePath or SqlIniFile settings in Proviso Config file for target server."; # vNEXT: this exception sucks... needs better info + link to docs... 
	}
	
	$ini = Read-SqlIniFile -FilePath $sqlConfigFile;
	$targetInstanceName = $ini.OPTIONS.INSTANCENAME.Replace("`"", "");
	
	# these details potentially needed whether NOT already installed OR if already installed and StrictInstall:$false:
	$sqlServiceName = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation .ServiceAccounts.SqlServiceAccountName" -Default "NT SERVICE\MSSQLSERVER";
	$agentServiceName = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation.ServiceAccounts.AgentServiceAccountName" -Default "NT SERVICE\SQLSERVERAGENT";
	
	if ($installedInstances -contains $targetInstanceName) {
		$strictOnly = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation.StrictInstallOnly" -Default $true;
		if ($strictOnly) {
			throw "SQL Server has already been installed, and StrictInstallOnly is set to `$true. Cannot Continue. Terminating...";
		}
		
		Write-Host "SQL Server has already been installed. Skipping SQL Server installation."; # vNEXT: Run high-level checks against version, service/account accounts, collation, SqlAuth, directories, features? and report/warn on any problems.
	}
	else {
		# vNEXT: options for encrypted and/or lookups of secure info like service and Sa Passwords. Implementation IF secure/lookup - then instead of "stringValue" we'll have @{ typeThingy = "blah", locationOfBlah = "another value", andSoOn = $true, $etc... }
		$sqlServicePassword = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation.ServiceAccounts.SqlServiceAccountPassword" -Default $null;
		$agentServicePassword = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation.ServiceAccounts.AgentServiceAccountPassword" -Default $sqlServicePassword;
			
		$saPassword = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation.SecuritySetup.SaPassword" -Default $null;
		$enableSqlAuth = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation.SecuritySetup.EnableSqlAuth" -Default $false;
		if (!($enableSqlAuth)) {
			$saPassword = $null;
		}
		
		$sysAdmins = @();
		foreach ($entry in (Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation.SecuritySetup.MembersOfSysAdmin" -Default @())) {
			$sysAdmins += $entry;
		}
		if ((Get-ConfigValue -Definition $serverDefinition -Key "SqlServerInstallation.SecuritySetup.AddCurrentUserAsAdmin" -Default $false)) {
			if ($env:USERNAME -eq "Administrator") {
				if (-not $sysAdmins -contains "BuiltIn\Administrators") {
				$sysAdmins += "BuiltIn\Administrators"
				}
			}
			else {
				$sysAdmins += $env:USERNAME;
			}
		}
		
		if ($sysAdmins.Count -lt 1) {
			throw "To continue, provide at least one WIndows account to provision as a SysAdmin. Terminating...";
		}
		
		$licenseKey = $serverDefinition.SqlServerInstallation["LicenseKey"];
		
		Install-SqlServer -SQLServerSetupPath $sqlInstallPath -ConfigFilePath $sqlConfigFile -SqlDirectories $sqlDirectories `
			  -SaPassword $saPassword -SysAdminAccountMembers $sysAdmins `
			  -SqlServiceAccountName $sqlServiceName -SqlServiceAccountPassword $sqlServicePassword `
			  -AgentServiceAccountName $agentServiceName -AgentServiceAccountPassword $agentServicePassword -LicenseKey $licenseKey;
	}
	
	# Expected Directories and Shares (which also ensures SQL Perms if/as needed... )
	Confirm-Directories -ServerDefinition $serverDefinition;
	Confirm-Shares -ServerDefinition $serverDefinition;
	
	# Process SQL Server Configuration:
	if ((Get-ConfigValue -Definition $serverDefinition -Key "SqlServerConfiguration.LimitSqlServerTls1dot2Only" -Default $true)) {
		Limit-SqlServerTlsOnly;
	}
	
	Install-SqlServerPowerShellModule; 
	
	if ((Get-ConfigValue -Definition $serverDefinition -Key "SqlServerConfiguration.GenerateSPN" -Default $false)) {
		# vNEXT: https://overachieverllc.atlassian.net/browse/PRO-43
		# note that we'll need Domain Admin creds here (pretty sure local admin won't work - right?)
		Write-Host "Skipping process of generating SPNs for target instance + service-account/ports/etc. - not yet implemented... ";
	}
	
	if ((Get-ConfigValue -Definition $serverDefinition -Key "SqlServerConfiguration.DisableSaLogin" -Default $false)) {
		Disable-SaLogin;
	}
	
	if ((Get-ConfigValue -Definition $serverDefinition -Key "SqlServerConfiguration.DeployContingencySpace" -Default $false)) {
		$drives = @();
		foreach ($d in $sqlDirectories.Values) {
			if (-not ($drives -contains ($d.Substring(0, 1)))) {
				$drives += $d.Substring(0, 1);
			}
		}
		
		Expand-ContingencySpace -TargetVolumes $drives -ZipSource (Join-Path -Path $script:resourcesRoot -ChildPath "assets\ContingencySpace.zip");
	}
	
	$lockPages = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerConfiguration.EnabledUserRights.LockPagesInMemory" -Default $true;
	$fastInit = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerConfiguration.EnabledUserRights.PerformVolumeMaintenanceTasks" -Default $false;
	Set-UserRightsForSqlServer -AccountName $sqlServiceName -LockPagesInMemory:$lockPages -PerformVolumeMaintenanceTasks:$fastInit;
	
	$flags = @();
	foreach ($flag in (Get-ConfigValue -Definition $serverDefinition -Key "SqlServerConfiguration.TraceFlags" -Default @())) {
		$flags += $flag;
	}
	Add-TraceFlags $flags;
	
	if ((Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.Deploy" -Default $true))  {
		
		$overrideSource = $null;
		$adminDbOverridePath = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.OverrideSource" -Default $null;
		if (-not ([string]::IsNullOrEmpty($adminDbOverridePath))) {
			if (Test-Path -Path $adminDbOverridePath) {
				$overrideSource = $adminDbOverridePath;
			}
			else {
				$provisoSource = Join-Path -Path $script:resourcesRoot -ChildPath $adminDbOverridePath;
				if (Test-Path -Path $provisoSource) {
					$overrideSource = $provisoSource;
				}
			}
		}
		
		Deploy-AdminDb -OverrideSource $overrideSource;
		
		Invoke-SqlCmd -Query "EXEC admindb.dbo.[enable_advanced_capabilities];";
		$script:adminDbInstalled = $true;
		
		# Configure Instance:	
		[string]$maxDOP = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConfigureInstance.MAXDOP" -Default $null;
		[string]$maxMEM = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConfigureInstance.MaxServerMemoryGBs" -Default $null;
		[string]$cTFP = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConfigureInstance.CostThresholdForParallelism" -Default 40;
		[string]$optForAdHoc = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConfigureInstance.OptimizeForAdHocQueries" -Default "1";
		Invoke-SqlCmd -Query "EXEC admindb.dbo.[configure_instance] 
			@MaxDOP = $maxDOP, 
		    @CostThresholdForParallelism = $cTFP, 
			@MaxServerMemoryGBs = $maxMEM,
			@OptimizeForAdhocWorkloads = $optForAdHoc ;";
		
		# Database Mail: 
		if ((Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.DatabaseMail.Enabled" -Default $true)) {
			
			[string]$operatorEmail = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.DatabaseMail.OperatorEmail";
			[string]$smtpAccountName = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.DatabaseMail.SmtpAccountName" -Default $null;
			[string]$smtpOutAddy = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.DatabaseMail.SmtpOutgoingEmailAddress";
			[string]$smtpServer = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.DatabaseMail.SmtpServerName";
			[string]$portNumber = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.DatabaseMail.SmtpPortNumber" -Default "587";
			[string]$requiresSsl = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.DatabaseMail.SmtpRequiresSSL" -Default "1";
			[string]$authType = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.DatabaseMail.SmtpAuthType" -Default "BASIC";
			[string]$userName = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.DatabaseMail.SmptUserName" -Default $null;
			[string]$password = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.DatabaseMail.SmtpPassword" -Default $null;
			[string]$sendEmail = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.DatabaseMail.SendTestEmailUponCompletion" -Default "1";
			
			Invoke-SqlCmd -Query "EXEC admindb.dbo.[configure_database_mail]
				@OperatorEmail = N'$operatorEmail',
				@SmtpAccountName = N'$smtpAccountName',
				@SmtpOutgoingEmailAddress = N'$smtpOutAddy',
				@SmtpServerName = N'$smtpServer',
				@SmtpPortNumber = $portNumber, 
				@SmtpRequiresSSL = $requiresSsl, 
			    @SmptUserName = N'$userName',
			    @SmtpPassword = N'$password', 
				@SendTestEmailUponCompletion = $sendEmail ; ";
		}
		
		# History Management: 
		if ((Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.HistoryManagement.Enabled" -Default $true)) {
			
			[string]$logCount = $serverDefinition.AdminDb.HistoryManagement.SqlServerLogsToKeep;
			[string]$agentJobRetention = $serverDefinition.AdminDb.HistoryManagement.AgentJobHistoryRetention;
			[string]$backupHistory = $serverDefinition.AdminDb.HistoryManagement.BackupHistoryRetention;
			[string]$emailRetention = $serverDefinition.AdminDb.HistoryManagement.EmailHistoryRetention;
			
			Invoke-SqlCmd -Query "EXEC admindb.dbo.[manage_server_history]
				@NumberOfServerLogsToKeep = $logCount,
				@AgentJobHistoryRetention = N'$agentJobRetention',
				@BackupHistoryRetention = N'$backupHistory',
				@EmailHistoryRetention = N'$emailRetention', 
				@OverWriteExistingJob = 1; ";
		}
		
		# Disk Monitoring: 	
		if ((Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.DiskMonitoring.Enabled" -Default $true)) {
			[string]$GBsThreshold = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.DiskMonitoring.WarnWhenFreeGBsGoBelow" -Default "18";
			
			Invoke-SqlCmd -Query "EXEC [admindb].dbo.[enable_disk_monitoring]
				@WarnWhenFreeGBsGoBelow = $GBsThreshold, 
				@OverWriteExistingJob = 1; ";
		}
		
		# Alerts 
		$ioAlerts = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.Alerts.IOAlertsEnabled" -Default $true;
		$severityAlerts = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.Alerts.SeverityAlertsEnabled" -Default $false;
		$alertTypes = "";
		
		if (($ioAlerts) -or ($severityAlerts)) {
			if (($ioAlerts) -and ($severityAlerts)) {
				$alertTypes = "SEVERITY_AND_IO";
			}
			else{
				if ($ioAlerts){
					$alertTypes = "IO";
				}
				else {
					$alertTypes = "SEVERITY";
				}
			}
			
			Invoke-SqlCmd -Query "EXEC [admindb].dbo.[enable_alerts] 
				@AlertTypes = N'$alertTypes'; ";
			
			$ioFilters = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.Alerts.IOAlertsFiltered" -Default $false;
			$severityFilters = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.Alerts.SeverityAlertsFiltered" -Default $false;
			if (($ioFilters) -or ($severityFilters)) {
				$filters = "";
				
				if (($ioFilters) -and ($severityFilters)) {
					$filters = "SEVERITY_AND_IO";
				}
				else {
					if ($ioFilters) {
						$filters = "IO";
					}
					else {
						$filters = "SEVERITY";
					}
				}
				
				Invoke-SqlCmd -Query "EXEC admindb.dbo.[enable_alert_filtering]
					@TargetAlerts = N'$filters'; ";
				
			}
		}
		
		if (Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.IndexMaintenance.Enabled" -Default $false) {
			
			$olasCodePath = Join-Path -Path $script:resourcesRoot -ChildPath "assets\hallengren_ix_optimize_only.sql";
			if (-not (Test-Path -Path $olasCodePath)) {
				throw "Asset 'hallengren_ix_optimize_only.sql' not found in ProvisoRoot\assets\ directory. Terminating... ";
			}
			
			Invoke-SqlCmd -InputFile $olasCodePath -DisableVariables;
			
			$weekDays = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.IndexMaintenance.DailyJobRunsOnDays" -Default $null;
			$weekEnds = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.IndexMaintenance.WeekendJobRunsOnDays" -Default "Su";
			$ixJobStartTime = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.IndexMaintenance.StartTime" -Default "21:50:00";
			$ixJobTimeZone = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.IndexMaintenance.TimeZoneForUtcOffset" -Default $null;
			$ixJobPrefix = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.IndexMaintenance.JobsNamePrefix" -Default "Index Maintenance"
			$ixJobCategory = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.IndexMaintenance.JobsCategoryName" -Default "Database Maintenance";
			$ixJobOperator = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.IndexMaintenance.OperatorToAlertOnErrors" -Default "Alerts";
			
			Invoke-SqlCmd -Query "EXEC admindb.dbo.[create_index_maintenance_jobs]
				@DailyJobRunsOnDays = N'$weekDays',
				@WeekendJobRunsOnDays = N'$weekEnds',
				@IXMaintenanceJobStartTime = N'$ixJobStartTime',
				@TimeZoneForUtcOffset = N'$ixJobTimeZone',
				@JobsNamePrefix = N'$ixJobPrefix',
				@JobsCategoryName = N'$ixJobCategory',
				@JobOperatorToAlertOnErrors = N'$ixJobOperator',
				@OverWriteExistingJobs = 1; ";
			
		}
		
		if (Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConsistencyChecks.Enabled" -Default $true) {
			$dbccDays = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConsistencyChecks.ExecutionDays" -Default "M, W, F, Su";
			$dbccStartTime = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConsistencyChecks.StartTime" -Default "04:10:00";
			$dbccTargets = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConsistencyChecks.Targets" -Default "{USER}";
			$dbccExclusions = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConsistencyChecks.Exclusions" -Default "";
			$dbccPriorities = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConsistencyChecks.Priorities" -Default "";
			$dbccLogicalChecks = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConsistencyChecks.IncludeExtendedLogicalChecks" -Default $false;
			$dbccTimeZone = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConsistencyChecks.TimeZoneForUtcOffset" -Default "";
			$dbccJobName = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConsistencyChecks.JobName" -Default "Database Consistency Checks";
			$dbccJobCategoryName = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConsistencyChecks.JobCategoryName" -Default "Database Maintenance";
			$dbccOperator = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConsistencyChecks.Operator" -Default "Alerts";
			$dbccProfile = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConsistencyChecks.Profile" -Default "General";
			$dbccSubject = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.ConsistencyChecks.JobEmailPrefix" -Default "[Database Corruption Checks] ";
			
			$dbccExtended = "0";
			if ($dbccLogicalChecks) {
				$dbccExtended = "1";
			}
			
			Invoke-SqlCmd -Query "EXEC admindb.dbo.[create_consistency_checks_job]
				@ExecutionDays = N'$dbccDays', 
				@JobStartTime = N'$dbccStartTime', 
				@JobName = N'$dbccJobName', 
				@JobCategoryName = N'$dbccJobCategoryName', 
				@TimeZoneForUtcOffset = N'$dbccTimeZone', 
				@Targets = N'$dbccTargets', 
				@Exclusions = N'$dbccExclusions', 
				@Priorities = N'$dbccPriorities', 
				@IncludeExtendedLogicalChecks = $dbccExtended, 
				@OperatorName = N'$dbccOperator', 
				@MailProfileName = N'$dbccProfile', 
				@EmailSubjectPrefix = N'$dbccSubject', 
				@OverWriteExistingJobs = 1;"
		}
		
		if (Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.Enabled" -Default $false) {
			
			$userDbTargets = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.UserDatabasesToBackup" -Default "{USER}";
			$userDbExclusions = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.UserDbsToExclude" -Default "";
			$certName = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.CertificateName" -Default "";
			$backupsDir = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.BackupDirectory" -Default "{DEFAULT}";
			$copyTo = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.CopyToDirectory" -Default "";
			$systemRetention = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.SystemBackupRetention" -Default "4 days";
			$copyToSystemRetention = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.CopyToSystemBackupRetention" -Default $systemRetention;
			$userRetention = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.UserBackupRetention" -Default "3 days";
			$copyToUserRetention = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.CopyToUserBackupRetention" -Default $userRetention;
			$logRetention = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.LogBackupRetention" -Default "73 hours";
			$copyToLogRetention = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.CopyToLogBackupRetention" -Default $logRetention;
			$allowForSecondaries = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.AllowForSecondaries" -Default $false;
			$fullSystemStart = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.SystemBackupsStart" -Default "18:50:00";
			$fullUserStart = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.UserBackupsStart" -Default "02:00:00";
			$diffsStart = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.DiffBackupsStart" -Default "";
			$diffsEvery = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.DiffBackupsEvery" -Default "";
			$logsStart = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.LogBackupsStart" -Default "00:02:00";
			$logsEvery = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.LogBackupsEvery" -Default "10 minutes";
			$backupsTimeZone = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.TimeZoneForUtcOffset" -Default "";
			$backupsPrefix = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.JobsNamePrefix" -Default "Datbase Backups - ";
			$backupsCategory = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.JobsCategoryName" -Default "Backups";
			$backupsOperator = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.Operator" -Default "Alerts";
			$backupsProfile = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.BackupJobs.Profile" -Default "General";
			
			$secondaries = "0";
			if ($allowForSecondaries) {
				$secondaries = "1";
			}
			
			Invoke-SqlCmd -Query "EXEC admindb.dbo.[create_backup_jobs]
				@UserDBTargets = N'$userDbTargets',
				@UserDBExclusions = N'$userDbExclusions',
				@EncryptionCertName = N'$certName',
				@BackupsDirectory = N'$backupsDir',
				@CopyToBackupDirectory = N'$copyTo',
				@SystemBackupRetention = N'$systemRetention',
				@CopyToSystemBackupRetention = N'$copyToSystemRetention',
				@UserFullBackupRetention = N'$userRetention',
				@CopyToUserFullBackupRetention = N'$copyToUserRetention',
				@LogBackupRetention = N'$logRetention',
				@CopyToLogBackupRetention = N'$copyToLogRetention',
				@AllowForSecondaryServers = $secondaries,
				@FullSystemBackupsStartTime = N'$fullSystemStart',
				@FullUserBackupsStartTime = N'$fullUserStart',
				@DiffBackupsStartTime = N'$diffsStart',
				@DiffBackupsRunEvery = N'$diffsEvery',
				@LogBackupsStartTime = N'$logsStart',
				@LogBackupsRunEvery = N'$logsEvery',
				@TimeZoneForUtcOffset = N'$backupsTimeZone',
				@JobsNamePrefix = N'$backupsPrefix',
				@JobsCategoryName = N'$backupsCategory',
				@JobOperatorToAlertOnErrors = N'$backupsOperator',
				@ProfileToUseForAlerts = N'$backupsProfile',
				@OverWriteExistingJobs = 1; ";			
		}
		
		if (Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.Enabled" -Default $false) {
			
			$restoreJobName = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.JobName" -Default "Database Backups - Regular Restore Tests";
			$restoreJobStart = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.JobStartTime" -Default "22:30:00";
			$restoreJobTimeZone = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.TimeZoneForUtcOffset" -Default "";
			$restoreJobCategory = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.JobCategoryName" -Default "Backups";
			$allowSecondaries = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.AllowForSecondaries" -Default $false;
			$dbsToRestore = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.DatabasesToRestore" -Default "{READ_FROM_FILESYSTEM}";
			$dbsToExclude = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.DatabasesToExclude" -Default "";
			$priorities = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.Priorities" -Default "";
			$backupsRoot = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.BackupsRootPath" -Default "{DEFAULT}";
			$restoreDataRoot = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.RestoreDataPath" -Default "{DEFAULT}";
			$restoreLogRoot = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.RestoreLogsPath" -Default "{DEFAULT}";
			$restorePattern = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.RestoredDbNamePattern" -Default "{0}_s4test";
			$allowReplace = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.AllowReplace" -Default "";
			$rpoThreshold = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.RpoThreshold" -Default "24 hours";
			$dropAfterRestore = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.DropDbsAfterRestore" -Default $true;
			$maxFailedDrops = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.MaxFailedDrops" -Default 3;
			$restoreOperator = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.Operator" -Default "Alerts";
			$restoreProfile = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.Profile" -Default "General";
			$emailPrefix = Get-ConfigValue -Definition $serverDefinition -Key "AdminDb.RestoreTestJobs.JobEmailPrefix" -Default "[RESTORE TEST] ";
			
			$secondaries = "0";
			if ($allowSecondaries) {
				$secondaries = "1";
			}
			
			$drop = "0";
			if ($dropAfterRestore) {
				$drop = "1";
			}
			
			Invoke-SqlCmd -Query "EXEC [admindb].[dbo].[create_restore_test_job]
				@JobName = N'$restoreJobName',
				@RestoreTestStartTime = N'$restoreJobStart',
				@TimeZoneForUtcOffset = N'$restoreJobTimeZone',
				@JobCategoryName = N'$restoreJobCategory',
				@AllowForSecondaries = N'$secondaries',
				@DatabasesToRestore = N'$dbsToRestore',
				@DatabasesToExclude = N'$dbsToExclude',
				@Priorities = N'$priorities',
				@BackupsRootPath = N'$backupsRoot',
				@RestoredRootDataPath = N'$restoreDataRoot',
				@RestoredRootLogPath = N'$restoreLogRoot',
				@RestoredDbNamePattern = N'$restorePattern',
				@AllowReplace = N'$allowReplace',
				@RpoWarningThreshold = N'$rpoThreshold',
				@DropDatabasesAfterRestore = $($drop),
				@MaxNumberOfFailedDrops = $maxFailedDrops,
				@OperatorName = N'$restoreOperator',
				@MailProfileName = N'$restoreProfile',
				@EmailSubjectPrefix = N'$emailPrefix',
				@OverWriteExistingJob = 1; ";			
		}
		
		# vNext: Monitoring Jobs (alerts on blocked-processes/killers), Metrics-Collection jobs, etc. 
	}
	
	# vNext: Encryption Certificates...  Scripted Logins/etc. 
	# vNext:   Or, instead of 'just' the above, maybe create a Environment/Custom Scripts entry - i.e., just a folder-path + list of files? 	
	
	if ((Get-ConfigValue -Definition $serverDefinition -Key "DataCollectorSets.Enabled" -Default $true)) {
		
		foreach ($collectorName in ($serverDefinition.DataCollectorSets.Keys | Where-Object { $_ -ne "Enabled" })){
			$collectorExists = Get-DataCollectorStatus -Name $collectorName;
			
			if ($collectorExists -eq "NotFound") {
				$xmlDefinition = Find-ProvisoAsset -ProvisoRoot $script:resourcesRoot -Asset $collectorName -AllowedExtensions "xml" -CorrectCase;
				if ($xmlDefinition -eq $null) {
					throw "Unable to locate XML definition file for Data Set Collector $collectoName - Please double-check config settings.";
				}
				
				Copy-Item $xmlDefinition -Destination "C:\PerfLogs" -Force;
				New-DataCollectorFromConfigFile -Name $collectorName -ConfigFilePath $xmlDefinition;
			}
			else {
				Write-Host "Skipping configuration checks against $collectorName - i.e., already exists.";
			}
			
			if ((Get-ConfigValue -Definition $serverDefinition -Key "DataCollectorSets.$collectorName.EnableStartWithOS" -Default $true)) {
				Enable-DataCollectorForAutoStart -Name $collectorName;
			}
				
			$daysToKeep = Get-ConfigValue -Definition $serverDefinition -Key "DataCollectorSets.$collectorName.DaysWorthOfLogsToKeep" -Default 0;
			if ($daysToKeep -gt 0) {
				$removeOldCollectorScriptPath = Find-ProvisoAsset -ProvisoRoot $script:resourcesRoot -Asset "Remove-OldCollectorSetFiles" -AllowedExtensions "ps1" -CorrectCase;
				if ($removeOldCollectorScriptPath -eq $null){
					throw "Error locating 'Remove-OldCollectorSetFiles.ps1' file in Proviso assets directory. This is needed for regular Data-CollectorSet cleanup. Terminating...";
				}
				
				Copy-Item $removeOldCollectorScriptPath -Destination "C:\PerfLogs" -Force;
				
				# setup cleanup
				New-CollectorSetFileCleanupJob -Name $collectorName -RetentionDays $daysToKeep;
			}
		}
	}
	
	if ((Get-ConfigValue -Definition $serverDefinition -Key "ExtendedEvents.DisableTelemetry" -Default $true)) {
		
		$majorVersion = 15;
		if ($script:adminDbInstalled) {
			$output = Invoke-SqlCmd -Query "SELECT admindb.dbo.get_engine_version()";
			$majorVersion = [int]($output.Column1);
		}
		
		Disable-TelemetryXEventsTrace -InstanceName $targetInstanceName -MajorVersion $majorVersion -CEIPServiceStartup "Disabled";
	}
	
	# enable/start AG health? 
	# foreach whatever in ExtendedEventsTraces ... add each trace as defined. 
	
	if ((Get-ConfigValue -Definition $serverDefinition -Key "SqlServerManagementStudio.InstallSsms" -Default $false)) {
		
		# Look for ssms.exe in the default location OR in the install-path that is OPTIONALLY specified in the .config.psd1 file... 
		$installPath = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerManagementStudio.InstallPath" -Default "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18";
		$found = Get-ChildItem -Path $installPath -Filter Ssms.exe -Recurse -ErrorAction SilentlyContinue;
		if (-not ($found)) {
			
			# vNEXT: allow option to download direct from MS - i.e., via the https://aka.ms/ssmsfullsetup uri... 
			$binaryPath = Find-SsmsBinaries -RootDirectory (Join-Path -Path $script:resourcesRoot -ChildPath "binaries\ssms") -Binary (Get-ConfigValue -Definition $serverDefinition -Key "SqlServerManagementStudio.Binary");
			$installAzure = Get-ConfigValue -Definition $serverDefinition -Key "SqlServerManagementStudio.IncludeAzureStudio" -Default $false;
			
			Install-SqlServerManagementStudio -Binaries $binaryPath -InstallPath $installPath -IncludeAzureDataStudio:$installAzure;
		}
	}
}
catch {
	Write-Host "Exception: $_";
	Write-Host "`t$($_.ScriptStackTrace)";
}
#endregion