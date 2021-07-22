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
	
	Install-Module -Name Proviso -Repository ProvisoRepo -Force;
	Import-Module -Name Proviso -Force;
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

try {
	
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
	
	$script:resourcesRoot = $pRoot;
	Load-Proviso;
	
	$matches = Find-MachineDefinition -RootDirectory (Join-Path -Path $script:resourcesRoot -ChildPath "definitions\servers") -MachineName ($env:COMPUTERNAME);
	
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
	
	$script:targetMachineFile = $mFile;
}
catch {
	Write-Host "Exception: $_";
	Write-Host "`t$($_.ScriptStackTrace)";
}
#endregion 

#region Core Workflow 
try {
	[PSCustomObject]$serverDefinition = Read-ServerDefinitions -Path $targetMachineConfig -Strict;
	
	# vNEXT: make this idempotent... i.e., check to see if cluster exists before attempting to create and so on.  (and feel free to throw big/ugly errors... 
	# vNEXT: ensure that Install-WsfcComponents has been called/executed (i.e., that we've got both of the modules/sets-of-tools in there loaded + we've rebooted - otherwise... done.)
	
	$clusterAction = Get-ConfigValue -Definition $serverDefinition -Key "ClusterConfiguration.ClusterAction" -Default "NONE";
	switch ($clusterAction){
		"NONE" {
			Write-Host "Cluster Action of `"NONE`" defined. Skipping Cluster Actions...";
		}
		"NEW" {
			
			
			# verify clustering installed (and not pending)
			$installed = (Get-WindowsFeature -Name Failover-Clustering).InstallState;
			if ($installed -ne "Installed") {
				throw "WSFC components are not installed (or may be installed and require a reboot). Cannot continue. Terminating...";
			}
			
			$clusterName = $serverDefinition.ClusterConfiguration.ClusterName;
			$clusterNodes = @();
			foreach ($node in $serverDefinition.ClusterConfiguration.ClusterNodes) {
				$clusterNodes += $node;
			}
			
			$clusterIPs = @();
			foreach ($ip in $serverDefinition.ClusterConfiguration.ClusterIPs) {
				$clusterIPs += $ip;
			}
			
			$witness = $serverDefinition.ClusterConfiguration.FileShareWitness;
			
			#New-WsfcCluster -ClusterName $clusterName -ClusterNodes $clusterNodes -ClusterIPs $clusterIPs -WitnessPath $witness;
			
		}
		"ADD" {
			throw "ADD is not yet implemented as a ClusterAction...  ";
		}
		"REMOVE"{
			throw "REMOVE is not implemented as a ClusterAction...";
		}
		default {
			Write-Host "Invalid or unexpected ClusterAction defined in ClusterConfiguration section.";
		}
	}
	
	$agAction = Get-ConfigValue -Definition $serverDefinition -Key "AvailabilityGroups.AGAction" -Default "NONE";
	
	
	
	
	
<# 
	
$partnerNames = "PodNames=$($PodName)SQL1,$($PodName)SQL2";
Invoke-SqlCmd -Query "EXEC admindb.dbo.[add_synchronization_partner]
    @PartnerNames = N'`$(PodNames)',
    @ExecuteSetupOnPartnerServer = 0; " -Variable $partnerNames -Credential $Credentials;

# -------------------------------------------------------------------
#        4.b - Configure/Set-up shell for Sync-Checks (Server, Jobs, Data)

Invoke-SqlCmd -Query "EXEC admindb.dbo.[create_sync_check_jobs]
    @Action = N'CREATE',
    @IgnoreSynchronizedDatabaseOwnership = 0,
    @IgnoredMasterDbObjects = N'',
    @IgnoredLogins = N'%NA_SQLSA%',
    @IgnoredAlerts = N'',
    @IgnoredLinkedServers = N'',
    @IgnorePrincipalNames = 0,
    @IgnoredJobs = N'',
    @IgnoredDatabases = N'',
    @OverWriteExistingJobs = 1; " -Credential $Credentials;

# -------------------------------------------------------------------
#        4.c - Create Failover Handler

Invoke-SqlCmd -Query "EXEC admindb.dbo.[add_failover_processing]
    @ExecuteSetupOnPartnerServer = 0; " -Credential $Credentials;	
	
	
#>
	
	
	
	
}
catch {
	Write-Host "Error: $_";
	Write-Host $_.ScriptStackTrace;
}

#endregion