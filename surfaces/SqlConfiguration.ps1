Set-StrictMode -Version 1.0;

Surface SqlConfiguration -Target "SqlServerConfiguration" {
	
	Assertions  {
		Assert-UserIsAdministrator; # can't set user rights otherwise... 
		Assert-SqlServerIsInstalled -SurfaceTarget "SqlServerConfiguration" -AssertOnConfigureOnly;
	}
	
	Aspect {
		Facet "ForceEncryptedConnections" -Key "LimitSqlServerTls1dot2Only" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				try {
					$path = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\' -ErrorAction SilentlyContinue).$instanceName;
					$currentValue = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$path\MSSQLServer\SuperSocketNetLib\" -Name "ForceEncryption" -ErrorAction SilentlyContinue).ForceEncryption;
					
					if ($currentValue -ne 1) {
						return $false;
					}
					
					return $true;
				}
				catch {
					throw "Exception Evaluating Registry for SQL Server 'Force Encryption' Settings.";
				}
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$expectedSetting = $PVContext.CurrentConfigKeyValue;
				
				if ($expectedSetting) {
					try {
						$path = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\' -ErrorAction SilentlyContinue).$instanceName;
						
						$currentValue = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$path\MSSQLServer\SuperSocketNetLib\" -Name "ForceEncryption" -ErrorAction SilentlyContinue).ForceEncryption;
						if ($currentValue -ne 1) {
							Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$path\MSSQLServer\SuperSocketNetLib\" -Name "ForceEncryption" -Value 1 -ErrorAction SilentlyContinue;
						}
						
						$PVContext.SetSqlRestartRequired("Change to force Encrypted Connections requires SQL Server Service RESTART.");
					}
					catch {
						throw "Exception enabling Encrypted Connections only against SQL Server Instance [$instanceName]: $_ `r`t$($_.ScriptStackTrace) ";
					}
				}
				else {
					$PVContext.WriteLog("Config setting for [SqlServerConfiguration.$instanceName.LimitSqlServerTls1dot2Only] is set to `$false - but $instanceName is already set to force encrypted connections. Proviso will NOT remove this configuration. Please make changes manually.", "Critical");
				}
			}
		}
		
		Facet "DisableSa" -Key "DisableSaLogin" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$result = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [is_disabled] FROM master.sys.[server_principals] WHERE [name] = 'sa';").is_disabled;
				
				if ($null -eq $result) {
					return $false;
				}
				
				return $result;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$expectedSetting = $PVContext.CurrentConfigKeyValue;
				
				if ($expectedSetting) {
					Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "ALTER LOGIN [sa] DISABLE; ";
				}
				else{
					$PVContext.WriteLog("Config setting for [SqlServerConfiguration.$instanceName.DisableSaLogin] is set to `$false - but the sa login for $instanceName is already disabled. Proviso will NOT remove this configuration. Please make changes manually.", "Critical");
				}
			}
		}
		
		Facet "ContingencySpace" -Key "DeployContingencySpace" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$sqlDirectories = @{};
				$sqlDirectories["InstallSqlDataPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceName.SqlServerDefaultDirectories.InstallSqlDataDir");
				$sqlDirectories["SqlDataPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceName.SqlServerDefaultDirectories.SqlDataPath");
				$sqlDirectories["SqlLogsPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceName.SqlServerDefaultDirectories.SqlLogsPath");
				$sqlDirectories["SqlBackupsPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceName.SqlServerDefaultDirectories.SqlBackupsPath");
				$sqlDirectories["TempDbPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceName.SqlServerDefaultDirectories.TempDbPath");
				$sqlDirectories["TempDbLogsPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceName.SqlServerDefaultDirectories.TempDbLogsPath");
				
				$drives = @();
				# TODO: refactor to just use a single loop ... 
				foreach ($d in $sqlDirectories.Values) {
					if (-not ($drives -contains ($d.Substring(0, 1)))) {
						$drives += $d.Substring(0, 1);
					}
				}
				
				foreach ($drive in $drives) {
					$contingencyPath = "$($drive):\ContingencySpace"
					
					if (-not (Test-Path $contingencyPath)) {
						$PVContext.WriteLog("Contingency Space missing from $contingencyPath", "Debug");
						return $false;
					}
					
					$count = 0;
					foreach ($child in (Get-ChildItem -Path $contingencyPath -Filter "PlaceHolder*.emptyspace")) {
						if ($child.Length / 1GB -eq 1) {
							$count++;
						}
					}
					
					if ($count -ne 4) {
						$PVContext.WriteLog("Count of contingency files in [$contingencyPath] is [$count].", "Debug");
						return $false
					}
				}
				
				return $true;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$expectedSetting = $PVContext.CurrentConfigKeyValue;
				
				$contingencyZipSource = $PVResources.GetAsset("ContingencySpace", "zip");
				if (-not (Test-Path $contingencyZipSource)) {
					throw "Asset [ContingencySpace.zip] not found. Unable to proceed.";
				}
				
				if ($expectedSetting) {
					$sqlDirectories = @{};
					$sqlDirectories["InstallSqlDataPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceName.SqlServerDefaultDirectories.InstallSqlDataDir");
					$sqlDirectories["SqlDataPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceName.SqlServerDefaultDirectories.SqlDataPath");
					$sqlDirectories["SqlLogsPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceName.SqlServerDefaultDirectories.SqlLogsPath");
					$sqlDirectories["SqlBackupsPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceName.SqlServerDefaultDirectories.SqlBackupsPath");
					$sqlDirectories["TempDbPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceName.SqlServerDefaultDirectories.TempDbPath");
					$sqlDirectories["TempDbLogsPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceName.SqlServerDefaultDirectories.TempDbLogsPath");
					
					$drives = @();
					
					foreach ($d in $sqlDirectories.Values) {
						if (-not ($drives -contains ($d.Substring(0, 1)))) {
							$drives += $d.Substring(0, 1);
						}
					}
					
					# TODO: refactor to use just a single loop (i.e., the one above... )
					foreach ($drive in $drives) {
						$contingencyPath = "$($drive):\ContingencySpace"
						$deployed = $false;
						
						if (Test-Path $contingencyPath) {
							$count = 0;
							foreach ($child in (Get-ChildItem -Path $contingencyPath -Filter "PlaceHolder*.emptyspace")) {
								if ($child.Length / 1GB -eq 1) {
									$count++;
								}
							}
							
							if ($count -eq 4) {
								$deployed = $true;
							}
						}
						
						if (-not ($deployed)) {
							$targetPath = "$($drive):\";
							Expand-Archive -Path $contingencyZipSource -DestinationPath $targetPath -Force;
							Copy-Item -Path $contingencyZipSource -Destination "$($targetPath)ContingencySpace\" -Force;
						}
					}
				}
				else {
					# TODO: foreach directory where contingency space should exist ... zip in and nuke it... 
					$PVContext.WriteLog("Config setting for [SqlServerConfiguration.$instanceName.DeployContingencySpace] is set to `$false - but Contingency Space is already deployed. Proviso will NOT remove this configuration. Please make changes manually.", "Critical");
				}
			}
		}
		
		Facet "UserRight:LPIM" -Key "EnabledUserRights.LockPagesInMemory" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				return Get-UserRightForSqlServer -InstanceName $instanceName -UserRight LPIM;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$expectedSetting = $PVContext.CurrentConfigKeyValue;
				
				try {
					if ($expectedSetting) {
						Set-UserRightForSqlServer -InstanceName $instanceName -UserRight LPIM;
					}
					else {
						Remove-UserRightForSqlServer -InstanceName $instanceName -UserRight LPIM;
					}
				}
				catch {
					$PVContext.WriteLog("Failure Setting/Removing [LockPagesInMemory]: $_ `r`t$($_.ScriptStackTrace) ", "Critical");
				}
				
				$PVContext.SetSqlRestartRequired("Addition of UserRight:LockPagesInMemory requires SQL Server Service RESTART.");
			}
		}
		
		Facet "UserRight:PVMT" -Key "EnabledUserRights.PerformVolumeMaintenanceTasks" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				return Get-UserRightForSqlServer -InstanceName $instanceName -UserRight PVMT;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$expectedSetting = $PVContext.CurrentConfigKeyValue;
				
				try {
					if ($expectedSetting) {
						Set-UserRightForSqlServer -InstanceName $instanceName -UserRight PVMT;
					}
					else {
						Remove-UserRightForSqlServer -InstanceName $instanceName -UserRight PVMT;
					}
				}
				catch {
					$PVContext.WriteLog("Failure Setting/Removing [PerformVolumeMaintenanceTasks]: $_ `r`t$($_.ScriptStackTrace) ", "Critical");
				}
				
				$PVContext.SetSqlRestartRequired("Addition of UserRight:PerformVolumeMaintenanceTasks requires SQL Server Service RESTART.");
			}
		}
		
		# vNEXT: https://overachieverllc.atlassian.net/browse/PRO-43
		# and... not sure if that means we HAVE to have domain creds (or not).
		#Facet "SPNExists" -ExpectValueForChildKey "GenerateSPN" {
		#	Test {
		#		
		#	}
		#	Configure {
		#		
		#	}
		#}		
		
		Facet "TraceFlag" -Key "TraceFlags" -Expect $true {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				$traceFlag = $PVContext.CurrentConfigKeyValue;
				
				$enabled = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "DBCC TRACESTATUS(`$(FLAG));" -Variable "FLAG=$traceFlag").Global;
				
				if ($enabled -eq 0) {
					return $false;
				}
				
				return $true;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$traceFlag = $PVContext.CurrentConfigKeyValue;
				
				# NOTE: if we're in here (i.e., doing configuration 'stuff') it's because 'required' trace flag is missing - i.e., no worries about needing to REMOVE them.
				try {
					Add-TraceFlag -InstanceName $instanceName -Flag $traceFlag;
					$PVContext.WriteLog("Trace Flag [$traceFlag] enabled for instance [$instanceName]. Restart of SQL Server instance is NOT required.", "Verbose");
				}
				catch {
					$PVContext.WriteLog("Failure to enable Trace Flag [$traceFlag] against SQL Server Instance [$instanceName]: $_ `r`t$($_.ScriptStackTrace) ", "Critical");
				}
			}
		}
	}
}