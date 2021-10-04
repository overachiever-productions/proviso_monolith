Set-StrictMode -Version 1.0;

<#
	Primary Purposes: 
		1. Syntactical Sugar / Redirection (i.e., allows input from 3x different options/locations + chaining).
		2. Loads file-paths if/as Proviso data if path is correct/etc. 
		3. Enables validation of Proviso data files/contents if/as needed. 

#>

function With {
	
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, ParameterSetName = "CustomObject")]
		[PSCustomObject]$Config,
		[Parameter(Position = 0, ParameterSetName = "Hashtable")]
		[Hashtable]$ConfigData,
		[Parameter(Position = 0, ParameterSetName = "File")]
		[string]$ConfigFile,
		[switch]$Force = $false, # causes/forces a reload... 
		[switch]$Strict = $false,
		[switch]$AllowGlobalDefaults = $false
	);
	
	begin {
		Limit-ValidProvisoDSL -MethodName "With";
		
		if (-not ([string]::IsNullOrEmpty($ConfigFile))) {
			if (-not (Test-Path -Path $ConfigFile)) {
				throw "Specified -ConfigFile path of $ConfigFile does not exist.";
			}
			
			try {
				$data = Import-PowerShellDataFile $ConfigFile;
				$Config = [PSCustomObject]$data;
			}
			catch {
				throw "Exception Loading Proviso Config File at $ConfigFile. $_  `r$($_.ScriptStackTrace) ";
			}
		}
		
		if ($null -ne $ConfigData) {
			$Config = [PSCustomObject]$ConfigData;
		}
		
		if ($null -eq $Config) {
			throw "Invalid -Config, -ConfigData, or -ConfigFile inputs specified. Proviso Config value is NULL.";
		}
	}
	
	process {
		if ($strict) {
			if ($null -eq $Config.TargetServer) {
				throw "-Strict set to TRUE, but Configuration.TargetServer value not set or found.";
			}
			
			$currentHostName = [System.Net.Dns]::GetHostName();
			if ($currentHostName -ne $Config.TargetServer) {
				throw "-Strict is set to TRUE, and Current Host Name of [$currentHostName] <> [$($Config.TargetServer)].";
			}
		}
		
		[bool]$addMembers = $true;
		if (($Config.PSObject.Properties.Name -eq "MembersConfigured") -and (-not($Force))) {
			$addMembers = $false;
		}
		
		# Add Properties and Methods:
		if ($addMembers) {
			Add-Member -InputObject $Config -MemberType NoteProperty -Name MembersConfigured -Value $true -Force;
			Add-Member -InputObject $Config -MemberType NoteProperty -Name Strict -Value $Strict -Force;
			if ($null -eq $Config.AllowGlobalDefaults) {
				Add-Member -InputObject $Config -MemberType NoteProperty -Name AllowGlobalDefaults -Value $AllowGlobalDefaults -Force;
			}
			else {
				$Config.AllowGlobalDefaults = $AllowGlobalDefaults; # whatever was handed in CLOSEST to processing (i.e., the COMMAND vs a 'stale' config file) 'wins'.
			}
			
			[scriptblock]$setValue = {
				param (
					[Parameter(Mandatory)]
					[ValidateNotNullOrEmpty()]
					[string]$Key,
					[Parameter(Mandatory)]
					[ValidateNotNullOrEmpty()]
					[string]$Value
				);
				
				Set-ProvisoConfigValueByKey -Config $this -Key $Key -Value $Value;
			}
			Add-Member -InputObject $Config -MemberType ScriptMethod -Name "SetValue" -Value $setValue -Force;
			
			[scriptblock]$getValue = {
				param (
					[ValidateNotNullOrEmpty()]
					# TODO: either see if there's a way to get ValidateNotNullOrEmpty to throw a 'friendly' error message, or implement one of my own...
					[string]$Key
				);
				
				$output = Get-ProvisoConfigValueByKey -Config $this -Key $Key;
				
				if ($null -ne $output) {
					return $output;
				}
				
				# account for instance-specific keys defaulted to MSSQLSERVER: 
				$match = [regex]::Matches($Key, '(ExpectedDirectories|SqlServerInstallation|SqlServerConfiguration|SqlServerPatches|AdminDb|ExtendedEvents|ResourceGovernor|CustomSqlScripts)\.MSSQLSERVER');
				if ($match) {
					$keyWithoutDefaultMSSQLServerName = $Key.Replace(".MSSQLSERVER", "");
					$output = Get-ProvisoConfigValueByKey -Config $this -Key $keyWithoutDefaultMSSQLServerName;
				}
				
				if ($null -ne $output) {
					return $output;
				}
				
				$firstLevelElementName = $Key.Split(".")[0];
				$firstLevelElement = Get-ProvisoConfigValueByKey -Config $this -Key $firstLevelElementName;
				if ($null -eq $firstLevelElement) {
					if (-not ($this.AllowGlobalDefaults)) {
						# first-level key doesn't exist i.e., check for global defaults... 
						throw "First-Level config key [$firstLevelElementName] not defined in configuration object and -AllowGlobalDefaults is false.";
					}
				}
				
				# If we haven't found an explicit value, grab a default (which may be null):
				$output = Get-ProvisoConfigDefault -Key $Key;
				
				if ($null -eq $output) {
					# in SOME cases, a requested value SHOULD exist (either explicitly or by default), and if it doesn't, we SHOULD throw... 
					switch -regex ($Key) {
						'Host\.NetworkDefinitions\.[^.]+\.AssumableIfNames' {
							throw "Host.NetworkDefinitions<interfaceName>.AssumableIfNames cannot be null or use defaults.";
						}
						'Host\.NetworkDefinitions\.[^.]+\.(IpAddress|Gateway|PrimaryDns|SecondaryDns)+' {
							throw "Host.NetworkDefinitions.<interfaceName> core networking details (IP, gateway, DNS) cannot be null or use defaults.";
						}
						'Host\.ExpectedDisks\..+.PhysicalDiskIdentifiers\..+' {
							throw "Host.ExpectedDisk.<diskName>.PhysicalDiskIdentifiers cannot be null or use defaults.";
						}
						'Host\.ExpectedDisks\..+.VolumeName' {
							throw "Host.ExpectedDisks.<diskName>.VolumeName (drive letter) cannot be null or use defaults.";
						}
						# TODO: this isn't correctly accounting for both MSSSQLSERVER and <empty>
						'SqlServerInstallation\.[^.]+\.ServiceAccounts\.' {
							# if we didn't find defaults, it's for a non-default instance and ... we can't use defaults/etc.
							throw "SqlServerInstallation.ServiceAccount details cannot be null or use defaults with non-default SQL Server instances.";
						}
						# ditto ... needs to account for MSSSQLSERVER|_
						'SqlServerInstallation\.[^.]+\.SqlServerDefaultDirectories\.' {
							throw "SqlServerInstallation.SQLServerDefaultDirectories cannot be null of use defaults.";
						}
						'TODO-match on cluster stuff here ' {
							throw "Need to implement cluster checks and AG checks and anything else that makes sense";
						}
					}
				}
				
				return $output;
			}
			
			Add-Member -InputObject $Config -MemberType ScriptMethod -Name "GetValue" -Value $getValue -Force;
		}
	}
	
	end {
		$global:PVConfig = $Config; # expose globally... 
		return $Config; # emit to pipeline.
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