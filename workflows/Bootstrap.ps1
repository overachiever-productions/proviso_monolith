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

#region core-workflow
try {
	Write-Host "Proviso Config: $script:configPath ";
	Write-Host "Proviso Resources Root: $script:resourcesRoot ";
	Write-Host "Target Machine File: $script:targetMachineFile ";
	
	# Restart-ServerAndResumeProviso -ProvisoRoot "\\storage\Lab\proviso\" -ProvisoConfigPath "C:\Scripts\proviso.config.psd1" -WorkflowFile "C:\Users\Administrator\Desktop\Bootstrap.ps1" -ServerName "PRO-99" -Force;
}
catch {
	Write-ProvisoLog -Message ("EXCEPTION: $_  `r$($_.ScriptStackTrace) ") -Level Critical;
}
#endregion