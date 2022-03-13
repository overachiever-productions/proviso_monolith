Set-StrictMode -Version 1.0;

<#
	Primary Purposes: 
		1. Syntactical Sugar / Redirection (i.e., allows input from 3x different options/locations + chaining).
		2. Loads file-paths if/as Proviso data if path is correct/etc. 
		3. Enables validation of Proviso data files/contents if/as needed. 
#>

function Target {
	[Alias("With")]
	
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, ParameterSetName = "CustomObject")]
		[PSCustomObject]$Config,
		[Parameter(Position = 0, ParameterSetName = "Hashtable")]
		[Hashtable]$ConfigData,
		[Parameter(Position = 0, ParameterSetName = "File")]
		[string]$ConfigFile,
		[Parameter(Position = 0, ParameterSetName = "CurrentHost")]
		[switch]$CurrentHost = $false,
		[switch]$Force = $false, 					# causes/forces a reload... 
		[switch]$Strict = $false,
		[switch]$AllowGlobalDefaults = $true
	);
	
	begin {
		Validate-MethodUsage -MethodName "Target";
		
		if ($Config) {
			Set-ConfigTarget -ConfigData $Config -Strict:$Strict -AllowDefaults:$AllowGlobalDefaults -Force:$Force;
		}
		
		if ($null -ne $ConfigData) {
			Set-ConfigTarget -ConfigData ([PSCustomObject]$ConfigData) -Strict:$Strict -AllowDefaults:$AllowGlobalDefaults -Force:$Force;
		}
		
		if (-not ([string]::IsNullOrEmpty($ConfigFile))) {
			if (-not (Test-Path -Path $ConfigFile)) {
				throw "Specified -ConfigFile path of $ConfigFile does not exist.";
			}
			
			try {
				$data = Import-PowerShellDataFile $ConfigFile;
				[PSCustomObject]$configData = [PSCustomObject]$data;
				Set-ConfigTarget -ConfigData $configData -Strict:$Strict -AllowDefaults:$AllowGlobalDefaults -Force:$Force;
			}
			catch {
				throw "Exception Loading Proviso Config File at $ConfigFile. $_  `r$($_.ScriptStackTrace) ";
			}
		}
		
		if ($CurrentHost) {
			if (-not ($PVResources.RootSet)) {
				throw "Switch [-CurrentHost] cannot be used when ProvisoResources.Root has not been set. Use Assign -ProvisoRoot to set.";
			}
			
			$Strict = $true; # force -Strict if/when $CurrentHost switch is in use... 
			
			$targetDir = Join-Path $PVResources.ProvisoRoot -ChildPath "definitions";
			$matches = Find-MachineDefinition -RootDirectory $targetDir -MachineName ([System.Net.Dns]::GetHostName());
			
			switch ($matches.Count) {
				0 {
					throw "Switch [-CurrentHost] could not locate a definition file for host: [$([System.Net.Dns]::GetHostName())].";
				}
				1 {
					try {
						$data = Import-PowerShellDataFile ($matches[0].Name);
						Set-ConfigTarget -ConfigData ([PSCustomObject]$data) -Strict:$Strict -AllowDefaults:$AllowGlobalDefaults -Force:$Force;
					}
					catch {
						throw "Exception Loading Proviso Config File at $($matches[0].Name) via [-CurrentHost]. $_  `r$($_.ScriptStackTrace) ";
					}
				}
				default {
					# > 1 ... and not zero - i.e., multiple matches. 
					throw "Switch [-CurrentHost] detected > MULTIPLE definition files for host: [$([System.Net.Dns]::GetHostName())].";
				}
			}
		}
		
		if ($null -eq $global:PVConfig) {
			throw "Invalid -Config, -ConfigData, -ConfigFile, or -CurrentHost(switch) inputs specified. Proviso Config value is NULL.";
		}
	}
	
	process {
#		if ($strict) {
#			if ($null -eq $Config.Host.TargetServer) {
#				throw "-Strict set to TRUE, but Configuration.Host.TargetServer value not set or found.";
#			}
#			
#			$currentHostName = [System.Net.Dns]::GetHostName();
#			if ($currentHostName -ne $Config.Host.TargetServer) {
#				throw "-Strict is set to TRUE, and Current Host Name of [$currentHostName] does not match [$($Config.Host.TargetServer)].";
#			}
#		}
		
#		[bool]$addMembers = $true;
#		if (($Config.PSObject.Properties.Name -eq "MembersConfigured") -and (-not($Force))) {
#			$addMembers = $false;
#		}
		
		# Add Properties and Methods:
		$addMembers = $false;
		if ($addMembers) {
#			Add-Member -InputObject $Config -MemberType NoteProperty -Name MembersConfigured -Value $true -Force;
#			Add-Member -InputObject $Config -MemberType NoteProperty -Name Strict -Value $Strict -Force;
#			if ($null -eq $Config.AllowGlobalDefaults) {
#				Add-Member -InputObject $Config -MemberType NoteProperty -Name AllowGlobalDefaults -Value $AllowGlobalDefaults -Force;
#			}
#			else {
#				$Config.AllowGlobalDefaults = $AllowGlobalDefaults; # whatever was handed in CLOSEST to processing (i.e., the COMMAND vs a 'stale' config file) 'wins'.
#			}
			
#			[scriptblock]$setValue = {
#				param (
#					[Parameter(Mandatory)]
#					[ValidateNotNullOrEmpty()]
#					[string]$Key,
#					[Parameter(Mandatory)]
#					[ValidateNotNullOrEmpty()]
#					[string]$Value
#				);
#				
#				Set-ProvisoConfigValueByKey -Config $this -Key $Key -Value $Value;
#			}
#			Add-Member -InputObject $Config -MemberType ScriptMethod -Name "SetValue" -Value $setValue -Force;
#			
#			[scriptblock]$getValue = {
#				param (
#					[ValidateNotNullOrEmpty()]
#					# TODO: either see if there's a way to get ValidateNotNullOrEmpty to throw a 'friendly' error message, or implement one of my own...
#					[string]$Key
#				);
#				
#				$output = Get-ProvisoConfigValueByKey -Config $this -Key $Key;
#				
#				if ($null -ne $output) {
#					return $output;
#				}
#				
#				# account for instance-specific keys defaulted to MSSQLSERVER: 
#				$match = [regex]::Matches($Key, '(ExpectedDirectories|SqlServerInstallation|SqlServerConfiguration|SqlServerPatches|AdminDb|ExtendedEvents|ResourceGovernor|CustomSqlScripts)\.MSSQLSERVER');
#				if ($match) {
#					$keyWithoutDefaultMSSQLServerName = $Key.Replace(".MSSQLSERVER", "");
#					$output = Get-ProvisoConfigValueByKey -Config $this -Key $keyWithoutDefaultMSSQLServerName;
#				}
#				
#				if ($null -ne $output) {
#					return $output;
#				}
#				
#				$firstLevelElementName = $Key.Split(".")[0];
#				$firstLevelElement = Get-ProvisoConfigValueByKey -Config $this -Key $firstLevelElementName;
#				if ($null -eq $firstLevelElement) {
#					if (-not ($this.AllowGlobalDefaults)) {
#						# first-level key doesn't exist i.e., check for global defaults... 
#						throw "First-Level config key [$firstLevelElementName] not defined in configuration object and -AllowGlobalDefaults is false.";
#					}
#				}
#				
#				# If we haven't found an explicit value, grab a default (which may be null):
#				$output = Get-ProvisoConfigDefault -Key $Key;
#				
#				# in SOME cases, a requested value SHOULD exist (either explicitly or by default), and if it doesn't, we SHOULD throw... 
#				if ($null -eq $output) {
#					switch -regex ($Key) {
#						'Host\.NetworkDefinitions\.[^.]+\.AssumableIfNames' {
#							throw "Host.NetworkDefinitions<interfaceName>.AssumableIfNames cannot be null or use defaults.";
#						}
#						'Host\.NetworkDefinitions\.[^.]+\.(IpAddress|Gateway|PrimaryDns|SecondaryDns)+' {
#							throw "Host.NetworkDefinitions.<interfaceName> core networking details (IP, gateway, DNS) cannot be null or use defaults.";
#						}
#						'Host\.ExpectedDisks\..+.PhysicalDiskIdentifiers\..+' {
#							throw "Host.ExpectedDisk.<diskName>.PhysicalDiskIdentifiers cannot be null or use defaults.";
#						}
#						'Host\.ExpectedDisks\..+.VolumeName' {
#							throw "Host.ExpectedDisks.<diskName>.VolumeName (drive letter) cannot be null or use defaults.";
#						}
#						# TODO: this isn't correctly accounting for both MSSQLSERVER and <empty>
#						'SqlServerInstallation\.[^.]+\.ServiceAccounts\.' {
#							[string[]]$parts = $Key -split '\.';
#							$instanceName = $parts[1];
#							
#							if ($instanceName -eq "MSSQLSERVER") {
#								$accountType = $parts[3];
#								$accountType = Get-SqlServerDefaultServiceAccount -InstanceName $instanceName -AccountType $accountType;
#							}
#							else {
#								# vNEXT: actually... this is pretty easy to configure... 
#								throw "SqlServerInstallation.<INSTANCE>.ServiceAccount details cannot be null or use defaults with non-default SQL Server instances.";
#							}
#						}
#						'SqlServerInstallation\.[^.]+\.SqlServerDefaultDirectories\.' {
#							[string[]]$parts = $Key -split '\.';
#							$instanceName = $parts[1];
#							
#							if ($instanceName -eq "MSSQLSERVER") {
#								$directoryName = $parts[3];
#								$output = Get-SqlServerDefaultDirectoryLocation -InstanceName $instanceName -SqlDirectory $directoryName;
#							}
#							else {
#								# vNEXT: will, eventually, allow for D:\<instanceName>\<defaultDir> as an option here - instead of throwing... 
#								throw "SqlServerInstallation.<INSTANCE>.SQLServerDefaultDirectories cannot be null or use defaults for instances OTHER than [MSSQLSERVER].";
#							}
#						}
#						'TODO-match on cluster stuff here ' {
#							throw "Need to implement cluster checks and AG checks and anything else that makes sense";
#						}
#					}
#				}
#				
#				return $output;
#			}
			
			#Add-Member -InputObject $Config -MemberType ScriptMethod -Name "GetValue" -Value $getValue -Force;
		}
	}
	
	end {
		#$global:PVConfig = $Config; 
	}
}

# -----------------------------------------------------------------------------------------------------------------------------
# Signature Tests:
#
#[PSCustomObject]$shares = [PSCustomObject]@{
#	TargetServer	    = "DESKTOP-IGOP6UN"
#	AllowGlobalDefaults = $false
#	
#	ExpectedShares	    = @{
#		SqlBackups = @{
#			SourceDirectory = "E:\SQLBackups"
#			ShareName	    = "SQLBackups"
#			ReadOnlyAccess  = @()
#			ReadWriteAccess = @(
#				"AWS\sqlservice"
#			)
#		}
#	}
#};
#
#[Hashtable]$shares2 = @{
#	ExpectedShares = @{
#		SqlBackups = @{
#			SourceDirectory = "E:\SQLBackups"
#			ShareName	    = "SQLBackups"
#			ReadOnlyAccess  = @()
#			ReadWriteAccess = @(
#				"AWS\sqlservice"
#			)
#		}
#	}
#};
#
#$shares3 = @{
#	ExpectedShares = @{
#		SqlBackups = @{
#			SourceDirectory = "E:\SQLBackups"
#			ShareName	    = "SQLBackups"
#			ReadOnlyAccess  = @()
#			ReadWriteAccess = @(
#				"AWS\sqlservice"
#			)
#		}
#	}
#};
#
#$sqlConfiguration = @{
#	SqlServerConfiguration = @{
#		MSSQLSERVER = @{
#			LimitSqlServerTls1dot2Only = $true
#			GenerateSPN			       = $true
#			DisableSaLogin			   = "=> this is a fake value for DisableSaLogin"
#			DeployContingencySpace	   = $true;
#			
#			EnabledUserRights		   = @{
#				LockPagesInMemory			  = $true
#				PerformVolumeMaintenanceTasks = $true
#			}
#			
#			TraceFlags				   = @(
#				3226
#				7745
#				7752
#			)
#		}
#	}
#}
#
#$sqlConfigurationWithoutMSSQLServer = @{
#	SqlServerConfiguration = @{
#		LimitSqlServerTls1dot2Only = $true
#		GenerateSPN			       = $true
#		DisableSaLogin			   = "=> this is a fake value for DisableSaLogin (without instance name specified)"
#		DeployContingencySpace	   = $true;
#		
#		EnabledUserRights		   = @{
#			LockPagesInMemory			  = $true
#			PerformVolumeMaintenanceTasks = $true
#		}
#		
#		TraceFlags				   = @(
#			3226
#			7745
#			7752
#		)
#	}
#}

#With $shares;		# explicit customObject
#With $shares2;		# explicit hashtable
#With $shares3;		# implicit hashtable
#With "\\storage\Lab\proviso\definitions\servers\PRO\PRO-100.psd1";  # file to a .psd1 ... 

# -----------------------------------------------------------------------------------------------------------------------------
# Consumer / Chaining Tests (verify that next call in the pipeline can get $config data as needed... )
#
#function Validate-Something {
#	
#	param (
#		[Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
#		[PSCustomObject]$Config
#	)
#	
#	#$someValue = $Config.GetValue("Host.ExpectedDisks.SqlScratch.ProvisioningPriority");
#	#$someValue = $Config.GetValue("SqlServerConfiguration.MSSQLSERVER.DisableSaLogin");
#	
#	$throwableValue = $Config.GetValue("Host.ExpectedDisks.DataDisk.PhysicalDiskIdentifiers.RawSize");
#	
#	Write-Host "Requested Config Value (with Defaults Enabled): $someValue ";
#}

#With $shares -Strict -AllowGlobalDefaults | Validate-Something;
#With "\\storage\Lab\proviso\definitions\servers\PRO\PRO-100.psd1" | Validate-Something;


#With $sqlConfiguration | Validate-Something;
#With $sqlConfigurationWithoutMSSQLServer | Validate-Something;

#With $shares -AllowGlobalDefaults | Validate-Something;