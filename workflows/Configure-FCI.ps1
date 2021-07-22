#Requires -RunAsAdministrator
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
	
	# TODO: spin up one of these per 'execution' - i.e., bind to a time-stamp ... 
	[string]$loggingPath = "C:\Scripts\proviso_log.txt";
	
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
	
#	Write-Log "Executing as $(whoami) ";
#	Write-Log "Starting Process of Loading Proviso... ";
	Load-Proviso;
	
	try {
#		Write-Log "MachineNameFromArgs: $targetMachine ";
#		Write-Log "ComputerNameFromEnv: $($env:COMPUTERNAME) ";
		$matches = Find-MachineDefinition -RootDirectory (Join-Path -Path $script:resourcesRoot -ChildPath "definitions\servers") -MachineName ($env:COMPUTERNAME);
		
	}
	catch {
		Write-Log "Boostrapping Exception: $_ ";
		throw;
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
			
			#Restart-ServerAndResumeProviso -ProvisoRoot $script:resourcesRoot -ProvisoConfigPath $script:configPath -WorkflowFile 
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
	
	# Data Collectors... (mostly just as a test... )
	if ((Get-ConfigValue -Definition $serverDefinition -Key "DataCollectorSets.Enabled" -Default $true)) {
		
		foreach ($collectorName in ($serverDefinition.DataCollectorSets.Keys | Where-Object {
					$_ -ne "Enabled"
				})) {
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
				if ($removeOldCollectorScriptPath -eq $null) {
					throw "Error locating 'Remove-OldCollectorSetFiles.ps1' file in Proviso assets directory. This is needed for regular Data-CollectorSet cleanup. Terminating...";
				}
				
				Copy-Item $removeOldCollectorScriptPath -Destination "C:\PerfLogs" -Force;
				
				# setup cleanup
				New-CollectorSetFileCleanupJob -Name $collectorName -RetentionDays $daysToKeep;
			}
		}
	}
#	
#	if ((Get-ConfigValue -Definition $serverDefinition -Key "ExtendedEvents.DisableTelemetry" -Default $true)) {
#		
#		$majorVersion = 15;
#		if ($script:adminDbInstalled) {
#			$output = Invoke-SqlCmd -Query "SELECT admindb.dbo.get_engine_version()";
#			$majorVersion = [int]($output.Column1);
#		}
#		
#		Disable-TelemetryXEventsTrace -InstanceName $targetInstanceName -MajorVersion $majorVersion -CEIPServiceStartup "Disabled";
#	}
#	
#	# enable/start AG health? 
#	# foreach whatever in ExtendedEventsTraces ... add each trace as defined. 
	
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