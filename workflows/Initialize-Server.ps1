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

#region core-workflow
try {
	[PSCustomObject]$serverDefinition = Read-ServerDefinitions -Path $script:targetMachineFile -Strict:$false;
	[string]$targetDomain = Get-ConfigValue -Definition $serverDefinition -Key "TargetDomain" -Default $null;
	[string]$targetServerName = Get-ConfigValue -Definition $serverDefinition -Key "TargetServer" -Default ($env:COMPUTERNAME);
	
	if (-not([string]::IsNullOrEmpty($targetDomain))) {
		[string]$currentDomain = (Get-CimInstance Win32_ComputerSystem).Domain;
		if (($targetDomain -ne $currentDomain) -or ($targetServerName -ne ($env:COMPUTERNAME))) {
			$creds = Get-Credential -Message "Please provide domain credentials for $targetDomain for user with ability to rename/add domain machines." -UserName "Administrator";
		}
	}
	
	# Network Adapters 
	[PSCustomObject]$currentAdapters = Get-ExistingAdapters;
	[PSCustomObject]$currentIpConfigurations = Get-ExistingIpConfiguration;
	Confirm-DefinedAdapters -ServerDefinition $serverDefinition -CurrentAdapters $currentAdapters -CurrentIpConfiguration $currentIpConfigurations;
	
	Start-Sleep -Milliseconds 3200; # Let network settings 'take' (especially for domain joins) before continuing... 
	
	# Computer Name
	if ($env:COMPUTERNAME -ne $serverDefinition.TargetServer) {
		
		[string]$hostName = $serverDefinition.TargetServer;
		if ([string]::IsNullOrEmpty($hostName)) {
			throw "Configuration is missing TargetServer definition - Terminating...";
		}
		
		[string]$targetDomain = $serverDefinition.TargetDomain;
		if ([string]::IsNullOrEmpty($targetDomain)) {
			
			Write-Host "Domain-Name not defined in current definition file. Renaming machine as member of WORKGROUP.";
			Rename-Server -NewMachineName $hostName;
			return;
		}
		
		Install-WindowsManagementCommands;
		
		# vNEXT: when executing the following to add to a domain... can get this error: "Add-Computer: Computer xxx was successfully joined to the domain xxx, but 
		#   ... renaming it to <new-name-here> failed with the following error message: The account already exists."
		#    which, of course it does if/when we're dealing with re-provisioning the same box over and over again. 
		#   ARGUABLY, that means that cleanup of the previous VM FAILED to clean up... BUT
		#      there could be an OPTION in the config below TargetServer/TargetDomain that says: EnableForcedSalvageOfDomainComputer = $false (by default)... 
		#     that, when found could/would go in and try to remove the machine in question - by using those AD powershell module tools? 
		
		# vNEXT: account for new scenario where: 
		#    - current VM is DOMAIN-JOINED ... i.e., it's ON the correct domain
		#    - it does NOT have the correct host-name (i.e., don't need to JOIN domain, just need to change the name)
		#    I've already coded the part up above where we'll grab creds for this kind of scenario...  but need to address the name change without throwing an error of "Hey, I'm already on such and such domain..."
		
		Rename-ServerAndJoinDomain -TargetDomain $targetDomain -Credentials $creds -NewMachineName $hostName -AllowRestart:$true;
	}
}
catch {
	Write-Host "Exception: $_";
	Write-Host "`t$($_.ScriptStackTrace)";
}
#endregion