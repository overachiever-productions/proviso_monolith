#Requires -RunAsAdministrator
Set-StrictMode -Version 1.0;

<# 
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

#region Boostrap

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
#endregion

try {
	$configFile = Find-ProvisoFile -TargetFileName "proviso.config.psd1";
	
	if ($configFile -ne $null) {
		$configData = Get-ConfigData -ConfigFilePath $configFile;
		
		$provisoRepo = $configData.ProvisoRepositoryName;
		$provisoFolder = $configData.ProvisoModulePath;
		$definitonsFolder = $configData.DefinitionsRootPath;
	}
	
	if ([string]::IsNullOrEmpty($provisoRepo) -and [string]::IsNullOrEmpty($provisoFolder)) {
		$provisoFolder = Request-Value -Message "Please Specify Path to ROOT directory where proviso.psm1 file is located";
	}
	
	if ([string]::IsNullOrEmpty($definitonsFolder)) {
		$definitonsFolder = Request-Value -Message "Please Specify Path to ROOT directory where <machine-name>.psd1 files are kept";
	}
	
	$targetMachineName = $env:COMPUTERNAME;
	$targetMachineConfig = Join-Path -Path $definitonsFolder -ChildPath "$($targetMachineName).psd1";
	
	if (([string]::IsNullOrEmpty($targetMachineConfig)) -or (-not (Test-Path -Path $targetMachineConfig))) {
		
		$targetMachineName = Request-Value -Message "Please specify name of Target VM to provision - e.g., `"SQL-97`".`n";
		$targetMachineConfig = Join-Path -Path $definitonsFolder -ChildPath "$($targetMachineName).psd1";
		
		if (([string]::IsNullOrEmpty($targetMachineConfig)) -or (-not (Test-Path -Path $targetMachineConfig))) {
			throw "Invalid Target-Machine definition file-path specified: $targetMachineConfig - Processing cannot continue. Terminating... ";
		}
	}
	
	Write-Host "Configuration file for host $targetMachineName located. Importing Proviso Module .... ";
	
	if (-not ([string]::IsNullOrEmpty($provisoRepo))) {
		Install-Module -Name Proviso -Repository $provisoRepo -Force;
		Import-Module -Name Proviso -Force;
	}
	else {
		$provisoPsm1 = Join-Path -Path $provisoFolder -ChildPath "Proviso.psm1";
		Import-Module $provisoPsm1 -Force;
	}
}
catch {
	Write-Host "Unexpected Error: ";
	Write-Host $_.ScriptStackTrace;
}
#endregion

#region Core Workflow 
try {
	[PSCustomObject]$serverDefinition = Read-ServerDefinitions -Path $targetMachineConfig -Strict;
	
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
		
		# vNEXT: This really doesn't need to be here - i.e., there's no need for this 'config' line in the .psd1 file. 
		#    it MAY turn out that I end up needing this in ... order to manage Listeners and such... but, that'd be transparent to end-users and won't need a line in the psd1/config...  
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
	
	if ($serverDefinition.FirewallRules.EnableICMP){
		Enable-Icmp;
	}
	
	# Disks:
	$definedVolumesAlreadyOnServer = Get-ExistingVolumeLetters;
	Initialize-DefinedDisks -ServerDefinition $serverDefinition -CurrentlyMountedVolumes $definedVolumesAlreadyOnServer -ProcessEphemeralDisksOnly:$false -Strict;
	
	# SQL Server Installation:
	$dataDirectory = $serverDefinition.SqlServerInstallation.SqlServerDefaultDirectories.SqlDataPath;
	$backupDirectory = $serverDefinition.SqlServerInstallation.SqlServerDefaultDirectories.SqlBackupsPath;
	
	$installSqlDataDir = $serverDefinition.SqlServerInstallation.SqlServerDefaultDirectories.InstallSqlDataDir;		# [OPTIONAL] 
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
		
		Write-Host "SQL Server has already been installed. Skipping SQL Server installtion."; # vNEXT: Run high-level checks against version, service/account accounts, collation, SqlAuth, directories, features? and report/warn on any problems.
		
		# vNEXT: if SqlServiceAccountName -eq $null/empty... then "NT SERVICE\MSSQLSERVER";
		$sqlServiceName = $serverDefinition.SqlServerInstallation.ServiceAccounts.SqlServiceAccountName;
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
		
		$sysAdmins = @();
		foreach ($entry in $serverDefinition.SqlServerInstallation.SecuritySetup.MembersOfSysAdmin) {
			$sysAdmins += $entry;
		}
		if ($serverDefinition.SqlServerInstallation.SecuritySetup.AddCurrentUserAsAdmin) {
			if ($env:USERNAME -eq "Administrator") {
				$sysAdmins += "BuiltIn\Administrators"
			}
			else{
				$sysAdmins += $env:USERNAME;
			}
		}
		
		if ($sysAdmins.Count -lt 1) {
			throw "To continue, provide at least one WIndows account to provision as a SysAdmin. Terminating...";
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
	
	$lockPages = $serverDefinition.SqlServerConfiguration.EnabledUserRights.LockPagesInMemory;
	$fastInit = $serverDefinition.SqlServerConfiguration.EnabledUserRights.PerformVolumeMaintenanceTasks;
	$userRightsPsm1Path = $serverDefinition.SqlServerConfiguration.EnabledUserRights.UserRightsPsm1Path;
	Set-UserRightsForSqlServer -AccountName $sqlServiceName -LockPagesInMemory:$lockPages -PerformVolumeMaintenanceTasks:$fastInit;
	
	if ($serverDefinition.SqlServerConfiguration.DeployContingencySpace) {
		# vNEXT: get a list of each 'distinct' disk within the $sqlDirectories variable... 
		
		# MVP implementation: 
		$drives = @("D");
		Expand-ContingencySpace -TargetVolumes $drives -ZipSource "\\storage\Lab\resources\ContingencySpace.zip";
	}
	
	if ($serverDefinition.SqlServerConfiguration.DisableSaLogin) {
		# vNEXT: 
		Write-Host "Skipping process of disabling SA login - not yet implemented... ";
	}
	
	$flags = @();
	foreach ($flag in $serverDefinition.SqlServerConfiguration.TraceFlags) {
		$flags += $flag;
	}
	Add-TraceFlags $flags;
	
	Restart-SQLServerAndAgent | Wait-ForSQLAccessAfterRestart;
	
	if ($serverDefinition.SqlServerManagementStudio.InstallSsms) {
		$binaryPath = $serverDefinition.SqlServerManagementStudio.BinaryPath;
		$installAzure = $serverDefinition.SqlServerManagementStudio.IncludeAzureStudio;
		
		Install-SqlServerManagementStudio -BinaryPath $binaryPath -IncludeAzureDataStudio:$installAzure;
	}
	
	if ($serverDefinition.AdminDb.Deploy) {
		$adminDbPath = $serverDefinition.AdminDb.SourcePath;
		
		Deploy-AdminDb -Source $adminDbPath;
	}
	
	if ($serverDefinition.AdminDb.EnableAdvancedCapabilities) {
		Invoke-SqlCmd -Query "EXEC admindb.dbo.[enable_advanced_capabilities];";
		
		# TODO: parse the output... and look for something that indicates if we need to restart or not... 
		Invoke-SqlCmd -Query "EXEC admindb.dbo.update_server_name @PrintOnly = 0;";
		
		Restart-SQLServerAndAgent | Wait-ForSQLAccessAfterRestart;
		
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