#Requires -RunAsAdministrator;
param (
	$targetMachine = $null,
	$autoRestart = $true
);

Set-StrictMode -Version 1.0;

#region boostrap
function Find-Config {
	foreach ($location in (Split-Path -Parent $PSCommandPath), "C:\Scripts", "C:\Scripts\proviso") {
		foreach ($ext in ".psd1", ".config", ".config.psd1") {
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

function Load-Proviso {
	$exists = Get-PSRepository | Where-Object {
		$_.Name -eq "ProvisoRepo"
	};
	
	if ($null -eq $exists) {
		$path = Join-Path -Path $script:resourcesRoot -ChildPath "repository";
		Register-PSRepository -Name ProvisoRepo -SourceLocation $path -InstallationPolicy Trusted;
	}
	
	Install-Module -Name Proviso -Repository ProvisoRepo -Confirm:$false -Force;
	Import-Module -Name Proviso -DisableNameChecking -Force;
	$provisoLoaded = $true;
	
	# Use Proviso to import other dependencies: 
	Assert-ProvisoRequiredModule -Name PSFramework -PreferProvisoRepo;
}

function Verify-ProvosioRoot {
	param (
		[string]$Directory
	);
	
	if (-not (Test-Path $Directory)) {
		return $null;
	}
	
	# vNEXT: override capabilities in .config can/will make this non-viable:
	foreach ($dir in "assets", "binaries", "definitions", "repository") {
		if (-not (Test-Path -Path (Join-Path -Path $Directory -ChildPath $dir))) {
			return $null;
		}
	}
	
	return $Directory;
}

function Write-Log {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Message,
		[string]$Level
	);
	
	if ($provisoLoaded) {
		Write-ProvisoLog -Message "BOOTSTRAP: $Message" -Level $Level;
	}
	else {
		[string]$loggingPath = "C:\Scripts\proviso_bootstrap.txt";
		
		if (-not ($script:log_initialized)) {
			if (Test-Path -Path $loggingPath) {
				Remove-Item -Path $loggingPath -Force;
			}
			
			New-Item $loggingPath -Value $Message -Force | Out-Null;
			$script:log_initialized = $true;
		}
		else {
			Add-Content $loggingPath $Message | Out-Null;
		}
	}
}
$provisoLoaded = $false;
$script:log_initialized = $false;

try {
	Disable-ScheduledTask -TaskName "Proviso - Workflow Restart" -ErrorAction SilentlyContinue | Out-Null;
	
	$script:configPath = Find-Config;
	$pRoot = $null;
	# vNEXT: 3x iterations of basically the SAME thing here... to get $pRoot. Convert this to a func that tries 3x diff paths. and save some lines of code. 
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
	Write-ProvisoLog -Message "Proviso Loaded." -Level Important;
	
	$matches = Find-MachineDefinition -RootDirectory (Join-Path -Path $script:resourcesRoot -ChildPath "definitions\servers") -MachineName ([System.Net.Dns]::GetHostName());
	if ($matches.Count -eq 0) {
		if (-not ($targetMachine -eq $null)) {
			$machineName = $targetMachine;
			Write-ProvisoLog -Message "Looking for config file for target machine: $machineName ... " -Level Debug;
		}
		else {
			$machineName = Request-Value -Message "Please specify name of Target VM to provision - e.g., `"SQL-97`".`n" -Default $null;
		}
		$matches = Find-MachineDefinition -RootDirectory (Join-Path -Path $script:resourcesRoot -ChildPath "definitions\servers") -MachineName $machineName;
	}
	
	$machineConfigFile = $null;
	switch ($matches.Count) {
		0 {
		} # nothing... $mFile stays $null... 
		1 {
			$machineConfigFile = $matches[0].Name;
		}
		default {
			#vNEXT: https://overachieverllc.atlassian.net/browse/PRO-88
			throw "Multiple/Duplicate .psd1 files (with the same machine name - in different sub-folders) are not, currently, supported.";
		}
	}
	
	$machineConfigFile = Test-ProvisoConfigurationFile -ConfigPath $machineConfigFile;
	if ($machineConfigFile -eq $null) {
		throw "Missing or Invalid Target-Machine-Name Specified. Please verify that a '<Machine-Name.psd1>' or '<Machine-Name>.config' file exists in the Resources-Root\definitions directory.";
	}
	$script:targetMachineFile = $machineConfigFile;
	
	Write-ProvisoLog -Message "Bootstrapping Process Complete." -Level Important;
}
catch {
	Write-Log -Message ("EXCEPTION: $_  `r$($_.ScriptStackTrace) ") -Level Critical;
}
#endregion 

#region Core Workflow 
try {
	[PSCustomObject]$serverDefinition = Read-ServerDefinitions -Path $script:targetMachineFile -Strict;
	
	$clusterType = Get-ConfigValue -Definition $serverDefinition -Key "ClusterConfiguration.ClusterType" -Default "NONE";
	
	# Grrr. this logic sucks... a switch... doesn't quite work though if/when FCI and AG both kind of do the same thing... 
	# 		i could try something like this: https://stackoverflow.com/questions/3493731/whats-the-powershell-syntax-for-multiple-values-in-a-switch-statement/3493778
	if ($clusterType -eq "NONE") {
		Write-ProvisoLog -Message "Cluster Action of `"NONE`" defined. Skipping Cluster Actions..." -Level Critical; # wouldn't be a big deal, but this workflow is the HA setup workflow, so no cluster type seems odd/problematic.
	}
	else {
		if (($clusterType -eq "AG") -or ($clusterType -eq "FCI")) {
			
			# verify clustering installed (and not pending)
			$installed = (Get-WindowsFeature -Name Failover-Clustering).InstallState;
			if ($installed -ne "Installed") {
				throw "WSFC components are not installed (or may be installed and require a reboot). Cannot continue. Terminating...";
			}
			
			$clusterName = Get-ConfigValue -Definition $serverDefinition -Key "ClusterConfiguration.ClusterName" -Default $null;
			if ([string]::IsNullOrEmpty($clusterName)) {
				throw "Cluster Name cannot be null/empty when ClusterType is set to either AG or FCI. Set ClusterType to NONE or specify a CluserName.";
			}
			$nodes = Get-ConfigValue -Definition $serverDefinition -Key "ClusterConfiguration.ClusterNodes" -Default $null;
			$ips = Get-ConfigValue -Definition $serverDefinition -Key "ClusterConfiguration.ClusterIPs" -Default $null;
			if (($null -eq $nodes) -or ($null -eq $ips)) {
				throw "Cluster Nodes and Cluster IPs MUST be specfied when ClusterType is set to AG or FCI.";
			}
			# vNext: allow witness types OTHER than FileShareWitnesses... 
			$witness = Get-ConfigValue -Definition $serverDefinition -Key "ClusterConfiguration.Witness.FileShareWitness" -Default $null;
			
			Write-Host "Target Cluster Name: $clusterName ";
			Write-Host "Cluster Nodes: $nodes ";
			Write-Host "Cluster IPs: $ips ";
			Write-Host "Witness: $witness ";
			
			# see if it exists: 
			$clusterExists = Get-Cluster $clusterName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
			if ($clusterExists) {
				Write-Host "Cluster Already Exists... querying for nodes... "
				# make sure that all nodes defined in $config are in the actual cluster and then.... hmmm... do whatever it takes to make them the same? 
				# yeah... this can/will get complex. 
				
			}
			else {
				Write-Host "No Cluster - creating... ";
				
				[PSCredential]$creds = Get-Credential -Message "Admin Creds:";
				
				New-WsfcCluster -ClusterName $clusterName -Credential $creds -ClusterNodes $nodes -ClusterIPs $ips -WitnessPath $witness;
				
			}
			
		}
		else {
			throw "INVALID or NON-SUPPORTED ClusterType Defined in ClusterCOnfiguration.ClusterType: $clusterType .";
		}
	}
	
	
<# 
		Otherwise, if/once we've got a cluster created and/or configured as desired, there's still a ton of crap that's needed for AGs: 
		
			- Verify Shares (Backups/etc.)
			- SQL Server Access to WSFC... + restart 
					> Grant-SqlServerAccessToWsfcCluster ??? 
		
			- Create/Ensure Mirroring(AG) Endpoint. 
				> and permissions on/against it... 
		
			- Ensure that cluster can create Listeners...  
				> i.e., run that process to pre-enable VCO/etc. to allow creation of stuff.. 
					https://docs.microsoft.com/en-us/archive/blogs/alwaysonpro/create-listener-fails-with-message-the-wsfc-cluster-could-not-bring-the-network-name-resource-online
			
			- deploy the following from/against admindb: 
				> PARTNER definitions. 
				> sync-check jobs
				> automated failover alerts/stuff. 
				> validate configuration (admindb)
	
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
	
	
		
		
		THEN, At this point, we're now ready to set up AGs: 
		
	
			- Create / Verify AG. 
				> Verify replicas
				> and/or add (and possibly REMOVE?) replicas? (yeah, probably never remove, just warn?)
	
			- Create / Verify Listener. 	
				> Name, Port#, IPs, etc. 
				> later: read-only routing... 
	
			- Per each listed/defined database for the AG in question
				> seed + add ... and push to preferred primary? 
					yeah, how do i establish the prefered primary? 
	
#>
	
	
}
catch {
	Write-ProvisoLog -Message ("EXCEPTION: $_  `r$($_.ScriptStackTrace) ") -Level Critical;
}

#endregion