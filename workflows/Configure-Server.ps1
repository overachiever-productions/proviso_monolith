#Requires -RunAsAdministrator
Set-StrictMode -Version 1.0;

<# 

	vNEXT: 
		uh... why prompt me for a host-name IF the host-name is 'correct'?
			e.g., initialize-server is what we use to get the host-name and network stuff in shape. 
			from that point forward (i.e., once this script runs/starts... 
			the expectation is that IF $env:ComputerName or whatever ... = $serverDefs.hostName and... maybe even domain-name/workgroup stuff... 
				then...at that point... don't ASK me for the name of a server, right? 



	SCOPE: 
		Preps host server prior to configuration by addressing the following 2x tasks/needs: 
			A. Windows / OS Preferences
			B. Host-Tls1.2Only
			C. Required Packages - i.e., WSFC, .NET3.5, AD Management, etc. 
			D. Firewall Rules
			E. Disks 
			F. SQL Directories/Prep
			G. SQL Server Installation. 
			H. Post SQL Install 
				- SQL-PowerShell, 
				- LimitTLS1.2, 
				- TraceFlags, 
				- User-Rights-Assignments
			I. Install/Deploy admindb. 
			J. Configure Instance
			K. Best-Practices Setup from Admindb
				- History Management
				- Alerts + Alert Filters 
				- Disk Monitoring


	CONVENTIONS: 
		

#>

# Globals:
[string]$targetMachineName = $null;
[string]$provisoRepo = $null;
[string]$provisoFolder = $null;
[string]$definitonsFolder = $null;

#region Helper Functions
function Find-ProvisoFile {
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$TargetFileName
	)
	
	# check the following locations for a desired file: 
	$currentLocation = Split-Path -Parent $PSCommandPath;
	
	[string[]]$locations = @(
		"$currentLocation"
		"C:\Scripts"
	);
	
	foreach ($location in $locations) {
		
		$fullPath = Join-Path -Path $location -ChildPath $targetFileName;
		
		if (Test-Path -Path $fullPath) {
			return $fullPath;
		}
	}
}

function Get-ConfigData {
	param (
		[string]$ConfigFilePath
	);
	
	[PSCustomObject](Import-PowerShellDataFile $ConfigFilePath);
}

function Request-Value {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Message,
		[string]$DefaultValue
	);
	
	if (!($output = Read-Host ($Message -f $DefaultValue))) {
		$output = $DefaultValue
	}
	
	return $output;
}
#endregion RegionName

#region Initialization Scaffolding
try {
	
	$configFile = Find-ProvisoFile -TargetFileName "proviso.config.psd1";
	
	if ($configFile -ne $null) {
		$configData = Get-ConfigData -ConfigFilePath $configFile;
		
		$provisoRepo = $configData.ProvisoRepositoryName;
		$provisoFolder = $configData.ProvisoModulePath;
		$definitonsFolder = $configData.DefinitionsRootPath;
	}
	
	if ([string]::IsNullOrEmpty($provisoRepo) -and [string]::IsNullOrEmpty($provisoFolder)) {
		# if not in default/convention path... request path. 	
		$provisoFolder = Request-Value -Message "Please Specify Path to ROOT directory where proviso.psm1 file is located";
	}
	
	if ([string]::IsNullOrEmpty($definitonsFolder)) {
		# if not in default/convention path... request path. (NOTE: repo not 'allowed' at this point - assuming stand-alone install.)
		$definitonsFolder = Request-Value -Message "Please Specify Path to ROOT directory where <machine-name>.psd1 files are kept";
	}
	
	$machineNamePrompt = "Please specify name of Target VM to provision - e.g., `"SQL-97`".`n";
	$targetMachineName = Request-Value -Message $machineNamePrompt;
	$targetMachineConfig = "";
	
	if (![string]::IsNullOrEmpty($definitonsFolder)) {
		$targetMachineConfig = Join-Path -Path $definitonsFolder -ChildPath "$($targetMachineName).psd1";
	}
	else {
		$targetMachineConfig = Find-ProvisoFile -TargetFileName "$($targetMachineName).psd1";
	}
	
	if (([string]::IsNullOrEmpty($targetMachineConfig)) -or (!(Test-Path -Path $targetMachineConfig))) {
		throw "Invalid Target-Machine definition file-path specified: $targetMachineConfig - Processing cannot continue. Terminating... ";
	}
	
	Write-Host "Configuration file for host $targetMachineName located. Importing Proviso Module .... ";
	
	if (!([string]::IsNullOrEmpty($provisoRepo))) {
		Install-Module -Name Proviso -Repository $provisoRepo -Force;
		Import-Module -Name Proviso;
	}
	else {
		$provisoPsm1 = Join-Path -Path $provisoFolder -ChildPath "Proviso.psm1";
		Import-Module $provisoPsm1;
	}
}
catch {
	Write-Host "Unexpected Error: ";
	Write-Host $_;
}
#endregion RegionName

#region Core Workflow 
try {
	[PSCustomObject]$serverDefinition = Read-ServerDefinitions -Path $targetMachineConfig -Strict:$false;
	
	# Tackle OS Preferences First: 
	$dvdDrive = if ($serverDefinition.WindowsPreferences.DvdDriveToZ) {
		"Z"
	}
	else {
		$null
	};
	
	$optimizeExplorer = $serverDefinition.WindowsPreferences.OptimizeExplorer;
	$disableServerManager = $serverDefinition.WindowsPreferences.DisableServerManagerOnLaunch;
	$diskCounters = $serverDefinition.WindowsPreferences.EnableDiskPerfCounters;
	$highPerf = $serverDefinition.WindowsPreferences.SetPowerConfigHigh;
	$disableMonitorTimeout = $serverDefinition.WindowsPreferences.DisableMonitorTimeout
	
	Set-WindowsServerPreferences `
		-TargetVolumeForDvdDrive $dvdDrive `
		-SetWindowsExplorerPreferences:$optimizeExplorer `
		-DisableServerManager:$disableServerManager `
		-EnableDiskPerfCounters:$diskCounters `
		-SetPowerConfigToHighPerf:$highPerf `
		-DisableMonitorTimeout:$disableMonitorTimeout `
		-Force;
	
	
	# Host TLS-Only (pre-reboot):
	if ($serverDefinition.LimitHostTls1dot2Only) {
		Limit-HostTls12Only;
	}
	
	# Required Packages
	if ($serverDefinition.RequiredPackages -ne $null) {
		if ($serverDefinition.RequiredPackages.WsfcComponents) {
			Install-WsfcComponents;
		}
		
		if ($serverDefinition.RequiredPackages.NetFxForPre2016InstancesRequired) {
			# TODO: Figure out the Windows Version: 
			$windowsVersion = "Windows2019";
			$netFxPath = $serverDefinition.RequiredPackages.NetFx35SxsRootPath;
			
			Install-NetFx35ForPre2016Instances -WindowsServerVersion $windowsVersion -NetFxSxsRootPath $netFxPath;
		}
		
		if ($serverDefinition.RequiredPackages.AdManagementFeaturesforPowershell6PlusRequired) {
			Install-ADManagementToolsForPowerShell6Plus;
		}
	}
	
	# Firewall Rules: 
	$enableFirewall = $serverDefinition.FirewallRules.EnableFirewallForSqlServer;
	$enableDAC = $serverDefinition.FirewallRules.EnableFirewallForSqlServerDAC;
	$enableMirroring = $serverDefinition.FirewallRules.EnableFirewallForSqlServerMirroring;
	if ($enableFirewall) {
		Unblock-FirewallForSqlServer -EnableDAC:$enableDAC -EnableMirroring:$enableMirroring -Silent;
	}
	
	$enableICMP = $serverDefinition.FirewallRules.EnableICMP;
	
	if ($enableICMP){
		Enable-Icmp;
	}
	
	# Disks:
	$definedVolumesAlreadyOnServer = Get-ExistingVolumeLetters;
	Initialize-DefinedDisks -ServerDefinition $serverDefinition -CurrentlyMountedVolumes $definedVolumesAlreadyOnServer -ProcessEphemeralDisksOnly:$false -Strict;
	
	# SQL Server Installation:
	$dataDirectory = $serverDefinition.SqlServerInstallation.SqlServerDefaultDirectories.SqlDataPath;
	$backupDirectory = $serverDefinition.SqlServerInstallation.SqlServerDefaultDirectories.SqlBackupsPath;
	
	$installSqlDataDir = $serverDefinition.SqlServerInstallation.SqlServerDefaultDirectories.InstallSqlDataDir;		# [OPTIONAL] within config; location of system dbs/etc. 
	$logsDirectory = $serverDefinition.SqlServerInstallation.SqlServerDefaultDirectories.SqlLogsPath; 				# [OPTIONAL]
	$tempdbDirectory = $serverDefinition.SqlServerInstallation.SqlServerDefaultDirectories.TempDbPath;				# [OPTIONAL]
	
	$installSqlDataDir = Set-DefaultForOptionalValue -OptionalValue $installSqlDataDir -DefaultValue $dataDirectory;
	$logsDirectory = Set-DefaultForOptionalValue -OptionalValue $logsDirectory -DefaultValue $dataDirectory;
	$tempdbDirectory = Set-DefaultForOptionalValue -OptionalValue $tempdbDirectory -DefaultValue $dataDirectory;
	
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
	$ini = Read-SqlIniFile -FilePath $serverDefinition.SqlServerInstallation.SqlInstallConfigPath;
	$targetInstanceName = $ini.OPTIONS.INSTANCENAME.Replace("`"", "");
	
	if ($installedInstances -contains $targetInstanceName) {
		$strictOnly = $serverDefinition.SqlServerInstallation.StrictInstallOnly;
		if ($strictOnly) {
			throw "SQL Server has already been installed, and StrictInstallOnly is set to `$true. Cannot Continue. Terminating...";
		}
		
		Write-Host "SQL Server has already been installed. Skipping SQL Server installtion.";
		# vNEXT: Run high-level checks against version, service/account accounts, collation, SqlAuth, directories, features? and report/warn on any problems.
	}
	else {
		
		# Define Installation Settings:
		$sqlInstallPath = $serverDefinition.SqlServerInstallation.SqlExePath;
		$sqlConfigFile = $serverDefinition.SqlServerInstallation.SqlInstallConfigPath;
		
		# vNEXT: if SqlServiceAccountName -eq $null/empty... then "NT SERVICE\MSSQLSERVER";
		#   and... if SqlServiceAccountName -like "NT SERVICE..\" AND AgentServiceAccountName null/empty, then "NT SERVICE\SQLSERVERAGENT"
		$sqlServiceName = $serverDefinition.SqlServerInstallation.ServiceAccounts.SqlServiceAccountName;
		$agentServiceName = $serverDefinition.SqlServerInstallation.ServiceAccounts.AgentServiceAccountName;
		
		# vNEXT: options for ... encrypted? passwords (and then some way to decrypt)
		#   and/or ... options for a lookup against some sort of a data-point. IF we're going to do/allow that though, then $xxxAccountPassword is an OBJECT - not a string - i.e., it'd become a new object with its own props vs being some sort of ugly string... 
		$sqlServicePassword = $serverDefinition.SqlServerInstallation.ServiceAccounts.SqlServiceAccountPassword;
		$agentServicePassword = $serverDefinition.SqlServerInstallation.ServiceAccounts.AgentServiceAccountPassword;
		
		if (![string]::IsNullOrEmpty($sqlServicePassword)) {
			$agentServicePassword = Set-DefaultForOptionalValue -OptionalValue $agentServicePassword -DefaultValue $sqlServicePassword;
		}
		
		$saPassword = $serverDefinition.SqlServerInstallation.SecuritySetup.SaPassword;
		$enableSqlAuth = $serverDefinition.SqlServerInstallation.SecuritySetup.EnableSqlAuth;
		if (!($enableSqlAuth)) {
			$saPassword = $null;
		}
		
		$addCurrentUserAsAdmin = $serverDefinition.SqlServerInstallation.SecuritySetup.AddCurrentUserAsAdmin;
		$sysAdmins = @();
		foreach ($entry in $serverDefinition.SqlServerInstallation.SecuritySetup.MembersOfSysAdmin) {
			$sysAdmins += $entry;
		}
		
		$licenseKey = $serverDefinition.SqlServerInstallation.LicenseKey;
		
		Install-SqlServer -SQLServerSetupPath $sqlInstallPath -ConfigFilePath $sqlConfigFile -SqlDirectories $sqlDirectories `
						  -SaPassword $saPassword -SysAdminAccountMembers $sysAdmins `
						  -SqlServiceAccountName $sqlServiceName -SqlServiceAccountPassword $sqlServicePassword `
						  -AgentServiceAccountName $agentServiceName -AgentServiceAccountPassword $agentServicePassword -LicenseKey $licenseKey;
	}
	
	# Expected Directories and Shares:
	Confirm-Directories -ServerDefinition $serverDefinition;
	Confirm-Shares -ServerDefinition $serverDefinition;
	
	foreach ($dir in $sqlDirectories.Values) {
		Grant-SqlServicePermissionsToDirectory -TargetDirectory $dir -SqlServiceAccountName $sqlServiceName;
	}
	
	# Process SQL Server Configuration:
	if ($serverDefinition.SqlServerConfiguration.LimitSqlServerTls1dot2Only) {
		Limit-SqlServerTlsOnly;
	}
	
	Install-SqlServerPowerShellModule; # vNEXT: how's this work for network-isolated VMs? 
	
	return;
	
# no worky - because UserRights doesn't work in PS 7 (and likely not in 6 either).
	$lockPages = $serverDefinition.SqlServerConfiguration.EnabledUserRights.LockPagesInMemory;
	$fastInit = $serverDefinition.SqlServerConfiguration.EnabledUserRights.PerformVolumeMaintenanceTasks;
	$userRightsPsm1Path = $serverDefinition.SqlServerConfiguration.EnabledUserRights.UserRightsPsm1Path;
	
	Set-UserRightsForSqlServer -AccountName "NT SERVICE\MSSSQLSERVER" -UserRightsPsm1Path $userRightsPsm1Path -LockPagesInMemory:$lockPages -PerformVolumeMaintenanceTasks:$fastInit;
	
	$flags = @();
	foreach ($flag in $serverDefinition.SqlServerConfiguration.TraceFlags) {
		$flags += $flag;
	}
	Add-TraceFlags $flags;
	
	Restart-SQLServerAndAgent | Wait-ForSQLAccess;
	
	if ($serverDefinition.AdminDb.Deploy) {
		$adminDbPath = $serverDefinition.AdminDb.SourcePath;
		
		Deploy-AdminDb -Source $adminDbPath;
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
	
	
}
catch {
	#vNext need some way of figuring out which command/operation we're IN currently - i.e., which function. 
	# I COULD do this the 'stupid' way - which would be: a) $currentOperation = "functionName" before starting EACH function call... and b) use that to determine/report-on-which func we were in when we crashed. 
	# but there has to be a way to do that within ... Powershell...  probably as a default variable or whatever...
	# yeah... looks like what i want would be in here (somewhere):
	#   https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7
	
	Write-Host "Error: $_";
	Write-Host $_.ScriptStackTrace;
}


#endregion