Set-StrictMode -Version 1.0;

filter Find-MachineDefinition {
	param (
		[Parameter(Mandatory)]
		[string]$RootDirectory,
		[Parameter(Mandatory)]
		[string]$MachineName
	);
	
	$matches = @{
	};
	[string[]]$extensions = ".psd1", ".config", ".config.psd1";
	
	$i = 0;
	foreach ($ext in $extensions) {
		foreach ($file in (Get-ChildItem -Path $RootDirectory -Filter "$MachineName$($ext)" -Recurse -ErrorAction SilentlyContinue)) {
			$matches[$i] = @{
				Name = $file.FullName;
				Size = $file.Length / 1KB
				Modified = $file.LastWriteTime;
			};
			
			$i++;
		}
	}
	
	return $matches;
}

# TODO: use a private variable instead: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/set-variable?view=powershell-7.2
$script:be8c742fMostRecentConfigFilePath = $null;
function Target {
	[Alias("With")]
	
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, ParameterSetName = "Hashtable")]
		[Hashtable]$ConfigData,
		[Parameter(Position = 0, ParameterSetName = "File")]
		[string]$ConfigFile,
		[Parameter(Position = 0, ParameterSetName = "CurrentHost")]
		[switch]$CurrentHost = $false,
		[Parameter(Position = 0, ParameterSetName = "HostHame")]
		[string]$HostName,
		[switch]$Strict = $true,
		[switch]$Force = $false, 		# inverse of Strict... 
		[switch]$AllowGlobalDefaults = $true
	);
	
	begin {
		Validate-MethodUsage -MethodName "Target";
				
		if ($Force) {
			$Strict = $false;
		}
		
		if ($null -ne $ConfigData) {
			Set-ConfigTarget -ConfigData ([PSCustomObject]$ConfigData) -Strict:$Strict -AllowDefaults:$AllowGlobalDefaults;
		}
		
		if (-not ([string]::IsNullOrEmpty($ConfigFile))) {
			if (-not (Test-Path -Path $ConfigFile)) {
				throw "Specified -ConfigFile path of $ConfigFile does not exist.";
			}
			
			try {
				$data = Import-PowerShellDataFile $ConfigFile;
				Set-ConfigTarget -ConfigData $data -Strict:$Strict -AllowDefaults:$AllowGlobalDefaults;
				$script:be8c742fMostRecentConfigFilePath = $ConfigFile;
			}
			catch {
				throw "Exception Loading Proviso Config File at $ConfigFile. $_  `r$($_.ScriptStackTrace) ";
			}
		}
		
		if ($HostName) {
			if ($PVCatalog.GetEnumeratedHosts() -notcontains $HostName) {
				throw "The -HostName argument can ONLY be used for definitions located in the ProvisoRoot\Definitions directory. Try using -ConfigFile to an explict path, or verify that the expected/targetted host config file is properly formatted.";
			}
			
			try {
				$hostConfigFile = $PVCatalog.GetHostConfigFileByHostName($HostName);
				$data = Import-PowerShellDataFile $hostConfigFile;
				
				Set-ConfigTarget -ConfigData $data -Strict:$Strict -AllowDefaults:$AllowGlobalDefaults;
				
				$script:be8c742fMostRecentConfigFilePath = $hostConfigFile;
			}
			catch {
				throw "Exception Loading Proviso Config File via -HostName at $ConfigFile. $_  `r$($_.ScriptStackTrace) ";
			}
		}
		
		if ($CurrentHost) {
			if (-not ($PVResources.RootSet)) {
				throw "Switch [-CurrentHost] cannot be used when ProvisoResources.Root has not been set. Use Assign -ProvisoRoot to set.";
			}
			
			$Strict = $true; #ALWAYS Force -Strict for -CurrentHost. 
			
			$targetDir = Join-Path $PVResources.ProvisoRoot -ChildPath "definitions";
			$matches = Find-MachineDefinition -RootDirectory $targetDir -MachineName ([System.Net.Dns]::GetHostName());
			
			switch ($matches.Count) {
				0 {
					throw "Switch [-CurrentHost] could not locate a definition file for host: [$([System.Net.Dns]::GetHostName())].";
				}
				1 {
					try {
						$data = Import-PowerShellDataFile ($matches[0].Name);
						Set-ConfigTarget -ConfigData $data -Strict:$Strict -AllowDefaults:$AllowGlobalDefaults;
						
						$script:be8c742fMostRecentConfigFilePath = ($matches[0].Name);
					}
					catch {
						throw "Exception Loading Proviso Config File at $($matches[0].Name) via [-CurrentHost]. $_  `r$($_.ScriptStackTrace) ";
					}
				}
				default {
					throw "Switch [-CurrentHost] detected > MULTIPLE definition files for host: [$([System.Net.Dns]::GetHostName())].";
				}
			}
		}
		
		if ($null -eq $global:PVConfig) {
			throw "Invalid -ConfigData, -ConfigFile, or -CurrentHost(switch) inputs specified. Proviso Config value is NULL.";
		}
	}
	
	process {

	}
	
	end {
		
	}
}