#Requires -RunAsAdministrator
Set-StrictMode -Version 1.0;

<# 

	SCOPE: 
		Preps host server prior to configuration by addressing the following 2x tasks/needs: 
			A. IP Configuration (Network Stack). 
			B. Host-Name and/or Domain Membership.

	CONVENTIONS: 
		
		All Proviso details will be found in C:\scripts unless otherwise, defined via proviso_config.psd1 OR if not-found in convention-default paths, will prompt: 
		
		C:\Scripts   convention root. 
			C:\Scripts\Modules\Proviso      (where the proviso module code will be found). 
			C:\Scripts\Definitions\ 		(where <machine-name>.psd1 files will be found). 


	vNEXT: 
		- for machine-rename operations... 
			a. postpone the reboot. 
			b. set up a JOB that fires 1x (upon restart - i.e., say 10 seconds after restart)
			b.2  as PART of this ... set up the proviso_config.psd1 file with all of the info gathered/configured from this scripts 'initialization' process 
				and... maybe even, also, put in a TargetMachineName value inside the .psd1 file as well? could even call it: TemporaryTargetMachineName or... 
					LocalDetails = @{
						TargetMachineNameDefinedFrom_InitializeServerr = "AWS-SQL-1D"... or whatever so that it's pretty clear where this config info came from?
					}	
			c. that runs ... Configure-Host.ps1 (and cleans up the old job)... 
			d. once that's all settled, ... then kick off the reboot. 

	vNEXT: 
		- check for domain-join operations 'early in' and prompt for creds at the onset of processing (i.e., right after getting a machine-name/psd1.

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
	
	# Network Adapters 
	[PSCustomObject]$currentAdapters = Get-ExistingAdapters;
	[PSCustomObject]$currentIpConfigurations = Get-ExistingIpConfiguration;
	Confirm-DefinedAdapters -ServerDefinition $serverDefinition -CurrentAdapters $currentAdapters -CurrentIpConfiguration $currentIpConfigurations;
	
	# wait for 3 seconds... i.e., let the new network changes 'take' (especially for domain joins/etc.)
	Start-Sleep -Milliseconds 3200;
	
	# Computer Name
	if ($env:COMPUTERNAME -ne $serverDefinition.TargetServer) {
		
		[string]$hostName = $serverDefinition.TargetServer;
		if ([string]::IsNullOrEmpty($hostName)) {
			throw "Configuration is missing HostName.MachineName definition - cannot continue.";
		}
		
		[string]$domainName = $serverDefinition.TargetDomain;
		if ([string]::IsNullOrEmpty($domainName)) {
			
			Write-Host "Domain-Name not defined in current definition file. Renaming machine as member of WORKGROUP.";
			Rename-Server -NewMachineName $hostName;
			return;
		}
		
		Install-WindowsManagementCommands;
		$creds = Get-Credential -Message "Please provide domain credentials for $domainName for user with ability to rename/add domain machines." -UserName "Administrator";
		# vNEXT: look at using parameter sets to create 2x fully different 'overloads' of Rename-Server - one with domain-name first, then creds... vs NewHostName first (i.e., non-domain join?)
		Rename-ServerAndJoinDomain -TargetDomain $domainName -Credentials $creds -NewMachineName $hostName -AllowRestart:$true;
	}
}
catch {
	Write-Host "Error: ";
	Write-Host $_;
}


#endregion RegionName