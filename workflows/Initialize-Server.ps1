#Requires -RunAsAdministrator
Set-StrictMode -Version 1.0;

<# 

	SCOPE: 
		Preps host server prior to configuration by addressing the following 2x tasks/needs: 
			A. IP Configuration (Network Stack). 
			B. Host-Name and/or Domain Membership.

	vNEXT: 
		- check for domain-join operations 'early in' and prompt for creds at the onset of processing (i.e., right after getting a machine-name/psd1.

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
	[PSCustomObject]$serverDefinition = Read-ServerDefinitions -Path $targetMachineConfig -Strict:$false;
	[string]$domainName = $serverDefinition.TargetDomain;
	[string]$currentDomain = (Get-CimInstance Win32_ComputerSystem).Domain;
	if ($domainName -ne $domainName) {
		$creds = Get-Credential -Message "Please provide domain credentials for $domainName for user with ability to rename/add domain machines." -UserName "Administrator";
	}
	
	# Network Adapters 
	[PSCustomObject]$currentAdapters = Get-ExistingAdapters;
	[PSCustomObject]$currentIpConfigurations = Get-ExistingIpConfiguration;
	Confirm-DefinedAdapters -ServerDefinition $serverDefinition -CurrentAdapters $currentAdapters -CurrentIpConfiguration $currentIpConfigurations;
	
	# Let network settings 'take' (especially for domain joins) before continuing... 
	Start-Sleep -Milliseconds 3200;
	
	# Computer Name
	if ($env:COMPUTERNAME -ne $serverDefinition.TargetServer) {
		
		[string]$hostName = $serverDefinition.TargetServer;
		if ([string]::IsNullOrEmpty($hostName)) {
			throw "Configuration is missing TargetServer definition - Terminating...";
		}
		
		[string]$domainName = $serverDefinition.TargetDomain;
		if ([string]::IsNullOrEmpty($domainName)) {
			
			Write-Host "Domain-Name not defined in current definition file. Renaming machine as member of WORKGROUP.";
			Rename-Server -NewMachineName $hostName;
			return;
		}
		
		Install-WindowsManagementCommands;
		Rename-ServerAndJoinDomain -TargetDomain $domainName -Credentials $creds -NewMachineName $hostName -AllowRestart:$true;
	}
}
catch {
	Write-Host "Error: ";
	Write-Host $_.ScriptStackTrace;
}
#endregion RegionName