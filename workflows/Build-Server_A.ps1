#Requires -RunAsAdministrator

Set-StrictMode -Version 1.0;
Import-Module ".\modules\S4Methods.psm1";


# Proviso TODO: 
#    Look at moving SOME/ALL? of this into a set of helper methods that 'orchestrate' things in the right order. 
#    i.e., see if there's a way to cleanly create a 'controller'-like 'function' as part of the module. 
# 			IF I do that, Build-Server or Provision-Server would make the most sense as names... except, those aren't approved verbs. 
#              options for approved verbs might be: Format-xxx, Initialize-Server... 
# 					Oh... duh: Build IS an approved verb... 
#						so is Deploy- ... which is perfect. (i.e., Build/Deploy are both perfect.)
# 							there's also Resume- ... which might be nice for calling 'view' or script to orchestrate after reboots
# 									(or, in other words, i'm GOING to have to break up functionality against reboots... )


# todo... create a convention and supporting code that takes @@MACHINENAME and ... uses that to go look for a definition.
# 			that said... one of the tasks of building a server is ... renaming the thing. so... can't/won't be able to use this convention very well out of the gate. hmmm

# hmmm. well. there's also the fact that this script has to sort of 'span' a reboot as well ... i.e., we'll start up and hostname will be x... 
#    then... we'll make changes then reboot... 
#   so... i guess, initially... start from any old script on the desktop? i.e., something that matches a specific pattern (lol, .psd1)

[string]$definitionPath = "D:\Dropbox\Repositories\S4\S4 Tools\PowerShell\definitions\hosts\AWS-SQL-1C.psd1"

# note: along the lines of the whole 'reboot' and such... MIGHT make sense to try and capture details about that reboot and account for it. 
# as in, the try/catch below is FINE. but... might make more sense to define some sort of $switch as a variable (here, in this script)
# 	and... then wrap a BIG chunk of the first bit of stuff in the try/catch below in a whole big "if($hasntRebooted -eq true) { do the early stuff} "
#     otherwise, skip ahead to the stuff where ... we're AFTER the machine reboot (rename - where -Strict) makes more sense. 

try {
	
	$serverDefinition = Read-ServerDefinitions -Path $definitionPath -Strict:$false;
	
	# Tackle OS Preferences First:
	if ($serverDefinition.Preferences.DvdDriveToZ) {
		Move-DvdDriveToZ;
	}
	
	# IDEMPOTENTIZE:
#	if ($serverDefinition.Preferences.OptimizeExplorer) {
#		Set-WindowsExplorerPreferences;
#	}
	
	if ($serverDefinition.Preferences.DisableServerManagerOnLaunch) {
		Disable-ServerManagerLaunchOnLogin;
	}
	
	if ($serverDefinition.Preferences.SetPowerConfigHigh) {
		Set-PowerConfigToHighPerformance;
	}
	
	if ($serverDefinition.Preferences.EnableDiskPerfCounters) {
		Enable-DiskPerfCounters;
	}
	
	# tackle this BEFORE reboot:
	if ($serverDefinition.LimitHostTls1dot2Only) {
		Limit-HostTls12Only;
	}
	
	# TODO: These operations HAVE to be idempotentized... 
	#Rename-NetworkInterface;
	#Set-NetworkAdapter -StaticIPAddress $staticIP -GatewayIPAddress $gateway -DnsServerAddresses $dns -PrefixLength $PrefixLength;
	#Write-Host "Network Adapter Set... sleeping for 4.5 seconds ... ";
	#Start-Sleep -Milliseconds 4800; # give the interface time to get jiggy with the new DC/DNS provider.
	
	# note... this is potentially scary if/when -Strict is NOT enabled:
	if ($env:COMPUTERNAME -ne $serverDefinition.TargetServer) {
		Rename-Machine -TargetDomain $domainName -Credentials $creds -NewMachineName $hostName;
		
		# at which point... we're going to reboot. 
		# meaning... probably makes sense to defer/remove the -Restart switch from rename/join operations... 
		
		# and then, in here, drop some sort of .tmp file or something that means we've rebooted - i.e., with a simple timestamp.
		# tyhat way, when the script fires up again... it'll see that file... (put it in windows/temp/), check the timestamp and ... if recent-ish
		# will simply skip ahead to the stuff past this point.
		# where... from here-on, we'll be doing stuff via -Strict;
	}
	
	# reload server definitions - and use -Strict ... i.e., we're at the point of making potentially lasting/scary changes:
	$serverDefinition = Load-ServerDefinitions -Path $definitionPath -Strict:$true;
	
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
	
	# Process Disks: 
	Initialize-DisksFromDefinitions -ServerDefinitionsPath $definitionPath -Strict;
	
	# firewall rules: 
	# TODO: Make these idempotent:
	if ($serverDefinition.FirewallRules.EnableFirewallForSqlServer) {
		Unblock-FirewallForSqlServer;
	}
	
	if ($serverDefinition.FirewallRules.EnableFirewallForSqlServerDAC) {
		Unblock-FirewallForSqlServerDAC;
	}
	
	if ($serverDefinition.FirewallRules.EnableFirewallForSqlServerMirroring) {
		Unblock-FirewallForSqlServerMirroring;
	}
	
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
	
	# Start SQL Server installation:
	
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
	foreach ($flag in $serverDefinition.SqlServerConfiguration.TraceFlags){
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
		$optForAdHoc = if(($serverDefinition.AdminDb.ConfigureInstance.OptimizeForAdHocQueries) -or ($serverDefinition.AdminDb.ConfigureInstance.OptimizeForAdHocQueries -eq "1")) { "1" } ELSE { "0" };
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


