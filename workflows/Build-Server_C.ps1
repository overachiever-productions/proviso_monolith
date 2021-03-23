<#

	AutoRun/Restart Fodder: 
			- https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7
			- https://stackoverflow.com/questions/15166839/powershell-reboot-and-continue-script
			- https://docs.microsoft.com/en-us/troubleshoot/windows-server/user-profiles-and-logon/turn-on-automatic-logon
			- https://www.reddit.com/r/PowerShell/comments/83w2bm/install_script_resume_after_restart/
			- https://cmatskas.com/configure-a-runonce-task-on-windows/


#>

#Requires -RunAsAdministrator
Set-StrictMode -Version 1.0;

Install-Module -Name Proviso -Repository "LabRepository";
Import-Module -Name Proviso;

[string]$definitionPath = "C:\Scripts\definitions\xx*.psm1"; # i.e., something that'll 'magically' load the definition... 

try {
	$serverDefinition = Read-ServerDefinitions -Path $definitionPath -Strict:$false;
	
	# Tackle OS Preferences First: 
	$dvdDrive = if($serverDefinition.Preferences.DvdDriveToZ) { "Z" } else { $null };  # TODO: change this to whatever... 
	$optimizeExplorer = $serverDefinition.Preferences.OptimizeExplorer;
	$disableServerManager = $serverDefinition.Preferences.DisableServerManagerOnLaunch;
	$diskCounters = $serverDefinition.Preferences.EnableDiskPerfCounters;
	$highPerf = $serverDefinition.Preferences.SetPowerConfigHigh;
	
	Set-WindowsServerPreferences
		-TargetVolumeForDvdDrive $dvdDrive
		-SetWindowsExplorerPreferences:$optimizeExplorer
		-DisableServerManager:$disableServerManager
		-EnableDiskPerfCounters:$diskCounters
		-SetPowerConfigToHighPerf:$highPerf
		-Force;
	
	# Host TLS-Only (pre-reboot):
	if ($serverDefinition.LimitHostTls1dot2Only) {
		Limit-HostTls12Only;
	}
	
	# Network Adapters 
	
	
	# Computer Name
	if ($env:COMPUTERNAME -ne $serverDefinition.TargetServer) {
		# note... this is potentially scary if/when -Strict is NOT enabled:
		
		Rename-Machine -TargetDomain $domainName -Credentials $creds -NewMachineName $hostName;
		
		# at which point... we're going to reboot. 
		# meaning... probably makes sense to defer/remove the -Restart switch from rename/join operations... 
		
		# and then, in here, drop some sort of .tmp file or something that means we've rebooted - i.e., with a simple timestamp.
		# tyhat way, when the script fires up again... it'll see that file... (put it in windows/temp/), check the timestamp and ... if recent-ish
		# will simply skip ahead to the stuff past this point.
		# where... from here-on, we'll be doing stuff via -Strict;
	}
	
	# Required Packages
	if ($serverDefinition.RequiredPackages -ne $null) {
		if ($serverDefinition.RequiredPackages.NetFxForPre2016InstancesRequired) {
			# TODO: Figure out the Windows Version: 
			$windowsVersion = "Windows2019";
			Install-NetFx35ForPre2016Instances -WindowsServerVersion $windowsVersion;
		}
		
		if ($serverDefinition.RequiredPackages.NetFxForPre2016InstancesRequired) {
			Install-ADManagementToolsForPowerShell6Plus;
		}
	}
	
	# Disks Initialization and Configuration
	$definedVolumesAlreadyOnServer = Get-Volume | Where-Object {
		$_.DriveLetter -ne $null
	} | Select-Object -ExpandProperty DriveLetter;
	
	Initalize-DisksFromDefinitions -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $definedVolumesAlreadyOnServer -ProcessEphemeralDisksOnly -Strict;
	# error handling/reporting/output-processing?
	# yeah... need to know if we can/should continue ... so need some sort of error... guess it would be -ErrorVariable or whatever... 
	
	
	# Firewall Rules: 
	$enableFirewall = $serverDefinition.FirewallRules.EnableFirewallForSqlServer;
	$enableDAC = $server.FirewallRules.EnableFirewallForSqlServerDAC;
	$enableMirroring = $server.FirewallRules.EnableFirewallForSqlServerMirroring;
	if ($enableFirewall) {
		Unblock-FirewallForSqlServer -EnableDAC:$enableDAC -EnableMirroring:$enableMirroring;
	}
		
	# Cluster Configuration Steps
	# IF we're supposed to 'cluster stuff' at this point... then, do it here... 
	if ($serverDefinition.ClusterConfiguration.ClusterAction -eq "PRE-NEW") {
		Install-WsfcComponents;
		
		# todo... load the following variables and stuff:
		
		New-WsfcCluster -ClusterName $clusterName -PrimaryNode $primaryName -SecondaryNode $secondaryName -ClusterIP1 $primaryIP -ClusterIP2 $secondaryIP -WitnessPath $fileShare -
	}
	if ($serverDefinition.ClusterConfiguration.ClusterAction -eq "PRE-JOIN") {
		Install-WsfcComponents;
		
		# todo, load varialbes and ... build a method to tackle adding a new node.
		Add-NodeToExistingWsfcCluster;
	}
	
	# SQL Server Installation
	
	# Get SQL Server Directories - then ensure they're created/defined (can't give them perms yet)
	$installSqlDataDir = $serverDefinition.SqlServerInstallation.SqlServerDefaultDirectories.InstallSqlDataDir;
	$dataDirectory = $serverDefinition.SqlServerInstallation.SqlServerDefaultDirectories.SqlDataPath;
	$logsDirectory = $serverDefinition.SqlServerInstallation.SqlServerDefaultDirectories.SqlLogsPath;
	$backupDirectory = $serverDefinition.SqlServerInstallation.SqlServerDefaultDirectories.SqlBackupsPath;
	$tempdbDirectory = $serverDefinition.SqlServerInstallation.SqlServerDefaultDirectories.TempDbPath;
	
	$sqlDirectories = @{
		InstallSqlDataDir = $installSqlDataDir
		SqlDataPath	      = $dataDirectory
		SqlLogsPath	      = $logsDirectory
		SqlBackupsPath    = $backupDirectory
		TempDbPath	      = $tempdbDirectory
	}
	
	foreach ($dir in $sqlDirectories.Value) {
		Mount-Directory -Path $dir;
	}
	
	# Define Installation Settings:
	$sqlInstallPath = $serverDefinition.SqlServerInstallation.SqlExePath;
	$sqlConfigFile = $serverDefinition.SqlServerInstallation.SqlInstallConfigPath;
	
	$sqlServiceName = $serverDefinition.SqlServerInstallation.ServiceAccounts.SqlServiceAccountName;
	$sqlServicePassword = $serverDefinition.SqlServerInstallation.ServiceAccounts.SqlServiceAccountPassword;
	$agentServiceName = $serverDefinition.SqlServerInstallation.ServiceAccounts.AgentServiceAccountName;
	$agentServicePassword = $serverDefinition.SqlServerInstallation.ServiceAccounts.AgentServiceAccountPassword;
	$licenseKey = $serverDefinition.SqlServerInstallation.LicenseKey;
	
	$enableSqlAuth = $serverDefinition.SqlServerInstallation.SecuritySetup.EnableSqlAuth;
	$saPassword = $serverDefinition.SqlServerInstallation.SecuritySetup.SaPassword; # required if the above is $true... 
	$addCurrentUserAsAdmin = $serverDefinition.SqlServerInstallation.SecuritySetup.AddCurrentUserAsAdmin;
	$sysAdmins = @();
	foreach ($entry in $serverDefinition.SqlServerInstallation.SecuritySetup.MembersOfSysAdmin) {
		$sysAdmins += $entry;
	}
	
	Install-SqlServer -SQLServerSetupPath $sqlInstallPath -ConfigFilePath $sqlConfigFile -SqlDirectories $sqlDirectories `
					  -SaPassword $saPassword -SysAdminAccountMembers $sysAdmins `
					  -SqlServiceAccountName $sqlServiceName -SqlServiceAccountPassword $sqlServicePassword `
					  -AgentServiceAccountName $sqlServiceName -AgentServiceAccountPassword $sqlServicePassword -LicenseKey $licenseKey;
	
	foreach ($dir in $sqlDirectories.Value) {
		Grant-SqlServicePermissionsToDirectory -TargetDirectory $dir;
	}
	
	
	# Post SQL Install/Configuration
	# Process SQL Server Configuration:
	if ($serverDefinition.SqlServerConfiguration.LimitSqlServerTls1dot2Only) {
		# doesn't work didn't throw errors ... but... doesn't work... 
		Limit-SqlServerTlsOnly;
	}
	
	Install-SqlServerPowerShellModule; # only installs if NOT found on box.
	
	
# no worky - because UserRights doesn't work in PS 7 (and likely not in 6 either).
	$lockPages = $serverDefinition.SqlServerConfiguration.EnabledUserRights.LockPagesInMemory;
	$fastInit = $serverDefinition.SqlServerConfiguration.EnabledUserRights.PerformVolumeMaintenanceTasks;
	Set-UserRightsForSqlServer -AccountName "NT SERVICE\MSSSQLSERVER" -LockPagesInMemory:$lockPages -PerformVolumeMaintenanceTasks:$fastInit;
	
	$flags = @();
	foreach ($flag in $serverDefinition.SqlServerConfiguration.TraceFlags) {
		$flags += $flag;
	}
	Add-TraceFlags $flags;
	
	Restart-SQLServerAndAgent | Wait-ForSQLAccess;
	
	if ($serverDefinition.AdminDb.Deploy) {
		$adminDbPath = $serverDefinition.AdminDb.SourcePath;
# no worky - something stupid about a parse error - even though I'm explicitly disabling variables... 
		Deploy-AdminDb -AdminDbPath $adminDbPath;
	}
	
	if ($serverDefinition.AdminDb.EnableAdvancedCapabilities) {
		Invoke-SqlCmd -Query "EXEC admindb.dbo.[enable_advanced_capabilities];";
		
		# TODO: parse the output... and look for something that indicates if we need to restart or not... 
		Invoke-SqlCmd -Query "EXEC admindb.dbo.update_server_name @PrintOnly = 0;";
		
		Restart-SQLServerAndAgent | Wait-ForSQLAccess;
		
		[string]$maxDOP = $serverDefinition.AdminDb.ConfigureInstance.MAXDOP;
		[string]$maxMEM = $serverDefinition.AdminDb.ConfigureInstance.MaxServerMemoryGBs;
		[string]$cTFP = $serverDefinition.AdminDb.ConfigureInstance.CostThresholdForParallelism;
		$optForAdHoc = if (($serverDefinition.AdminDb.ConfigureInstance.OptimizeForAdHocQueries) -or ($serverDefinition.AdminDb.ConfigureInstance.OptimizeForAdHocQueries -eq "1")) {
			"1"
		}
		ELSE {
			"0"
		};
		Invoke-SqlCmd -Query "EXEC admindb.dbo.[configure_instance] 
	@MaxDOP = $maxDOP, 
    @CostThresholdForParallelism = $cTFP, 
	@MaxServerMemoryGBs = $maxMEM,
	@OptimizeForAdhocWorkloads = $optForAdHoc ;";
		
	}
	
	# database mail:
	# TODO: via config
	Invoke-SqlCmd -Query "EXEC admindb.dbo.[configure_database_mail]
		@OperatorEmail = N'mike@overachiever.net',
		@SmtpAccountName = N'AWS - East',
		@SmtpOutgoingEmailAddress = N'alerts@overachiever.net',
		@SmtpServerName = N'email-smtp.us-east-1.amazonaws.com',
		@SmtpPortNumber = 587, 
		@SmtpRequiresSSL = 1, 
	    @SmptUserName = N'AKIAI2QUP43VN5VRF73Q',
	    @SmtpPassword = N'AkbYdzRcUiM1BqsqcCLbRi3fgE7pvRXgq8snFHAr6KKE', 
		@SendTestEmailUponCompletion = 1; ";
	
	# TODO: via config
	Invoke-SqlCmd -Query "EXEC admindb.[dbo].[manage_server_history]
		@EmailHistoryRetention = N'6 months'; ";
	
	# TODO: via config
	Invoke-SqlCmd -Query "EXEC [admindb].dbo.[enable_disk_monitoring]
		@WarnWhenFreeGBsGoBelow = 48; ";
	
	# TODO: via config
	Invoke-SqlCmd -Query "EXEC [admindb].dbo.[enable_alerts] 
		@AlertTypes = N'SEVERITY_AND_IO'; ";
	
	# TODO: via config	
	Invoke-SqlCmd -Query "EXEC admindb.dbo.[enable_alert_filtering]
		--@TargetAlerts = N'SEVERITY',  -- MKC: needs to be updated to allow 'types'. not currently supported. it's currently {ALL} - exclusions... 
		@ExcludedAlerts = N''; ";
	
	# TODO: via config
	Invoke-SqlCmd -Query "EXEC [admindb].dbo.[create_backup_jobs]
		@UserDBTargets = N'{USER}',
		@FullUserBackupsStartTime = N'02:00:00',
	    @OverwriteExistingJobs = 1; ";
	
	# TODO: via config
	Invoke-SqlCmd -Query "EXEC [admindb].dbo.[create_restore_test_job]
		@DatabasesToRestore = N'{USER}',
		@Priorities = N'x3',
		@RestoredDbNamePattern = N'{0}_s4test',
		@DropDatabasesAfterRestore = 1,
		@MaxNumberOfFailedDrops = 3,
		@OverWriteExistingJob = 1; ";
	
	# monitoring/jobs:
	
	
	# AG prep/etc. 	
	
	
	
	# Data Collector Sets: 
	# foreach <entry> in DataCollectorSets ... 
	#   a. Create the Data CollectorSet: 
	# 			New-DataCollectorFromConfigFile -Name [node/key-name] -ConfigFile "path to local or ... a downloaded file like admindb.latest?";
	#   b. make sure the collector is set to auto-start if needed. 
	# 	c. start the collector if defined as well. 
	
	<#	
	
	Which means the SCHEMA for DataCollectors has to change. 
		right now it's a set of simple name-value-pairs - e.g.:
	
				DataCollectorSets = @{
					Consolidated    = "path to xml file"
					AnyOtherSetHere = "path the the name here"
				}	
	
	
		  instead, I believe it should be expanded to: an array of arrays: 

	
	DataCollectorSets = @{
		Consolidated  = @{
			Definition = "Path to the definition here"
			StartCollector = $true   #with both of these defaulted to $true if they're not set? 
			EnableAutoStart = $true
		}
	
		AnotherCollectorHere = @{
			etc...
		}
	}
	
	
	#>
	
	
	
}
catch {
	#vNext need some way of figuring out which command/operation we're IN currently - i.e., which function. 
	# I COULD do this the 'stupid' way - which would be: a) $currentOperation = "functionName" before starting EACH function call... and b) use that to determine/report-on-which func we were in when we crashed. 
	# but there has to be a way to do that within ... Powershell...  probably as a default variable or whatever...
	# yeah... looks like what i want would be in here (somewhere):
	#   https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7
	
	Write-Host "Error: ";
	Write-Host $_;
}
