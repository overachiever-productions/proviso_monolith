Set-StrictMode -Version 1.0;

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
		[switch]$Strict = $true,
		[switch]$AllowGlobalDefaults = $true
	);
	
	begin {
		Validate-MethodUsage -MethodName "Target";
		
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
			}
			catch {
				throw "Exception Loading Proviso Config File at $ConfigFile. $_  `r$($_.ScriptStackTrace) ";
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