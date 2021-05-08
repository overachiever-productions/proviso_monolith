#Requires -RunAsAdministrator
Set-StrictMode -Version 1.0;


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
	
	if (([string]::IsNullOrEmpty($targetMachineConfig)) -or (-not(Test-Path -Path $targetMachineConfig))) {
		throw "Invalid Target-Machine definition file-path specified: $targetMachineConfig - Processing cannot continue. Terminating... ";
	}
	
	Write-Host "Configuration file for host $targetMachineName located. Importing Proviso Module .... ";
	
	if (-not([string]::IsNullOrEmpty($provisoRepo))) {
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
	
	# vNEXT: make this idempotent... i.e., check to see if cluster exists before attempting to create and so on.  (and feel free to throw big/ugly errors... 
	# vNEXT: ensure that Install-WsfcComponents has been called/executed (i.e., that we've got both of the modules/sets-of-tools in there loaded + we've rebooted - otherwise... done.)
	switch ($serverDefinition.ClusterConfiguration.ClusterAction){
		"NONE" {
			Write-Host "Cluster Action of `"NONE`" defined. Skipping Cluster Actions...";
		}
		"NEW" {
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
			
			New-WsfcCluster -ClusterName $clusterName -ClusterNodes $clusterNodes -ClusterIPs $clusterIPs -WitnessPath $witness;
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
}
catch {
	Write-Host "Error: $_";
	Write-Host $_.ScriptStackTrace;
}

#endregion