Set-StrictMode -Version 3.0;

#regsion boostrap
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
	
	if (-not($output = Read-Host ($Message -f $Default))) {
		$output = $Default
	}
	
	return $output;
}

function Get-ConfigData {
	param (
		[string]$ConfigFile
	);
	
	[PSCustomObject](Import-PowerShellDataFile $ConfigFile);
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
	$repos = Get-PSRepository;
	if (-not ($repos -contains "ProvisoRepo")) {
		$path = Join-Path -Path $script:resourcesRoot -ChildPath "repository";
		Register-PSRepository -Name ProvisoRepo -SourceLocation $path -InstallationPolicy Trusted;
	}
	
	Install-Module -Name Proviso -Repository ProvisoRepo -Force;
	Import-Module -Name Proviso -Force;
}

#function Verify-MachineConfig {
#	param (
#		[string]$ConfigPath,
#		[string]$MachineName
#	);
#	
#	$path = Join-Path -Path $ConfigPath -ChildPath "$($MachineName).psd1";
#	if (-not (Test-Path -Path $path)) {
#		$path = $path.Replace(".psd1", ".config");
#	}
#	
#	if (-not (Test-Path -Path $path)) {
#		return $null;
#	}
#	
#	$config = Get-ConfigData -ConfigFile $path;
#	if ([string]::IsNullOrEmpty($config)) {
#		return $null;
#	}
#	
#	if ([string]::IsNullOrEmpty($config.NetworkDefinition)) {
#		return $null;
#	}
#	
#	return $ConfigPath;
#}


try {
	$configPath = Find-Config;
	$pRoot = $null;
	if (-not ([string]::IsNullOrEmpty($configPath))) {
		$pRoot = (Get-ConfigData -ConfigFile $configPath).ResourcesRoot;
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
		$pRoot = Verify-ProvosioRoot -Directory $pRoot;
	}
	
	if ([string]::IsNullOrEmpty($pRoot)) {
		throw "Invalid Proviso Resources-Root Directory Specified. Please check proviso.config.psd1 and/or input of response to previous request. Terminating...";
	}
	
	$script:resourcesRoot = $pRoot;
	
	
	
	
	
	# TODO: need to allow for recursing of file-names - as per above... 
#	$tMachineConfig = Verify-MachineConfig -ConfigPath $script:resourcesRoot -MachineName "$($env:COMPUTERNAME)";
#	if ([string]::IsNullOrEmpty($tMachineConfig)) {
#		$tMachineConfig = Request-Value -Message "Please specify name of Target VM to provision - e.g., `"SQL-97`".`n" -Default $null;
#		$tMachineConfig = Verify-MachineConfig -ConfigPath $script:resourcesRoot -MachineName $tMachineConfig;
#	}
#	
#	if ([string]::IsNullOrEmpty($tMachineConfig)) {
#		throw "Invalid Target-Machine-Name Specified. Please verify that a '<Machine-Name.psd1>' or '<Machine-Name>.config' file exists in the Resources-Root\definitions directory.";
#	}
	
	
	
}
catch {
	Write-Host "Exception:`n$($_.ScriptStackTrace)";
}

#endregion 

#region core-workflow
#try {
#	
#}
#catch {
#	Write-Host "Exception:`n$($_.ScriptStackTrace)";
#}
#endregion
