Set-StrictMode -Version 1.0;

<#


# TODO:
   figure out which directives (to setup.exe) to NUKE/REMOVE based up on VERSION of SQL Server being installed. 
	Also... pretty sure that means I need to pass the $Version in to Install-SqlServer (er... well, yeah: duh: i do)

#>

Surface SqlInstallation -Target "SqlServerInstallation" {
	Assertions {
		Assert "Service Accounts Are Valid" -ConfigureOnly -FailureMessage "One or More Service Accounts Failed Authentication" {
			$instances = $PVConfig.GetSqlInstanceNames("SQLServerInstallation");
			if (($null -eq $instances) -or ($instances.Count -lt 1)) {
				throw "Invalid Configuration. "
			}
			
			$multipleInstances = $false;
			if ($instances.Count -gt 1) {
				$multipleInstances = $true;
			}
			
			foreach ($instance in $instances) {
				
				[string[]]$keyPrefixes = @("SqlServiceAccount", "AgentServiceAccount", "FullTextServiceAccount");
				foreach ($key in $keyPrefixes) {
					$accountName = $PVConfig.GetValue("SqlServerInstallation.$($instance).ServiceAccounts.$($key)Name");
					if ($accountName -notlike "NT SERVICE\*") {
						$accountPassword = Escape-PasswordCharactersForCommandLineUsage -Password ($PVConfig.GetValue("SqlServerInstallation.$($instance).ServiceAccounts.$($key)Password"));
						
						if (-not (Validate-WindowsCredentials -User $accountName -Password $accountPassword)) {
							$FailureMessage = "UserName + Password for [$accountName] Failed Authentication Test.";
							if ($multipleInstances) {
								$FailureMessage = "UserName + Password for [$accountName] for instance [$instance] Failed Authentication Test.";
							}
							
							return $false;
						}
					}
				}
			}
			
			return $true;
		}
		
		Assert "SysAdmin Members Exist" -ConfigureOnly -FailureMessage "One or more targets for inclusion as a Member of SysAdmin does not exist." {
			
			$instances = $PVConfig.GetSqlInstanceNames("SQLServerInstallation");
			if (($null -eq $instances) -or ($instances.Count -lt 1)) {
				throw "Invalid Configuration. "
			}
			
			$multipleInstances = $false;
			if ($instances.Count -gt 1) {
				$multipleInstances = $true;
			}
			
			foreach ($instance in $instances) {
				$sysAdminTargets = $PVConfig.GetValue("SqlServerInstallation.$instance.SecuritySetup.MembersOfSysAdmin");
				
				foreach ($admin in $sysAdminTargets) {
					
					$sid = ConvertTo-WindowsSecurityIdentifier -Name $admin;
					if ($null -eq $sid) {
						$FailureMessage = "Windows User/Group [$admin] does NOT exist.";
						if ($multipleInstances) {
							$FailureMessage = "Windows User/Group [$admin] for instance [$instance] does NOT exist.";
						}
						
						return $false;
					}
				}
			}
			
			return $true;
		}
	}
	
	Aspect {
		Facet "InstanceExists" -NoKey -ExpectIteratorValue -UsesBuild {
			Test {
				$instanceKey = $PVContext.CurrentSqlInstance;
				$installedInstances = Get-ExistingSqlServerInstanceNames;
				
				if ($instanceKey -in $installedInstances) {
					$PVContext.SetSurfaceState("$instanceKey.Installed", $true);
					return $instanceKey;
				}
				
				$PVContext.SetSurfaceState("$instanceKey.Installed", $false);
				return "";
			}
		}
		
		# TODO: re-implement equivalent of -IgnoreOnEmptyConfig
		Facet "Version" -Key "Setup.Version" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
		
				return (Get-SqlServerInstanceDetailsFromRegistry -InstanceName $instanceName -Detail "VersionName");
			}
		}
		
		# TODO: re-implement equivalent of -IgnoreOnEmptyConfig
		Facet "Edition" -Key "Setup.Edition" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
				
				return (Get-SqlServerInstanceDetailsFromRegistry -InstanceName $instanceName -Detail "Edition");
			}
		}
		
		# https://overachieverllc.atlassian.net/browse/PRO-181
#		Facet "Features" -ExpectValueForChildKey "Setup.Features" -UsesBuild {
#			Test {
#				$instanceName = $PVContext.CurrentKeyValue;
#				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
#					return "";
#				}
#				
#				return "<TODO...>";
#			}
#		}
		
		Facet "Collation" -Key "Setup.Collation" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
				
				return (Get-SqlServerInstanceDetailsFromRegistry -InstanceName $instanceName -Detail "Collation");
			}
		}
		
		Facet "SqlServiceAccount" -Key "ServiceAccounts.SqlServiceAccountName" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
				
				if ($instanceName -ne "MSSQLSERVER") {
					throw "Non-Default instance-names not YET supported.";
				}
				
				$serviceName = "MSSQLSERVER";
				return (Get-CimInstance -ClassName Win32_Service -Filter "Name='$serviceName'" | Select-Object -Property StartName).StartName;
			}
		}
		
		Facet "SqlAgentAccount" -Key "ServiceAccounts.AgentServiceAccountName" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
				
				if ($instanceName -ne "MSSQLSERVER") {
					throw "Non-Default instance-names not YET supported.";
				}
				
				$serviceName = "SQLSERVERAGENT";
				return (Get-CimInstance -ClassName Win32_Service -Filter "Name='$serviceName'" | Select-Object -Property StartName).StartName;
			}
		}
		
		Facet "AllowSqlAuth" -Key "SecuritySetup.EnableSqlAuth" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
				
				return Get-SqlServerInstanceDetailsFromRegistry -InstanceName $instanceName -Detail "MixedMode";
			}
		}
		
		# members of sys-admin... 
		
		Facet "DataPath" -Key "SQLServerDefaultDirectories.SqlDataPath" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
				
				return Get-SqlServerInstanceDetailsFromRegistry -InstanceName $instanceName -Detail "DefaultData";
			}
		}
		
		Facet "LogsPath" -Key "SQLServerDefaultDirectories.SqlLogsPath" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
				
				return Get-SqlServerInstanceDetailsFromRegistry -InstanceName $instanceName -Detail "DefaultLog";
			}
		}
		
		Facet "BackupsPath" -Key "SQLServerDefaultDirectories.SqlBackupsPath" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
				
				return Get-SqlServerInstanceDetailsFromRegistry -InstanceName $instanceName -Detail "DefaultBackups";
			}
		}
		
		# https://overachieverllc.atlassian.net/browse/PRO-180
		#		Facet "TempDbPath" -ExpectChildKeyValue "SQLServerDefaultDirectories.TempDbPath" -UsesBuild {
		#			Test {
		#				$instanceName = $PVContext.CurrentKeyValue;
		#				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
		#					return "";
		#				}
		#				
		#				# TODO: account for non-default instance-names... 		
		#				
		#				#$query = "SELECT RTRIM(LEFT([physical_name], LEN([physical_name]) - CHARINDEX(N'\', REVERSE([physical_name])))) [path] FROM sys.[database_files] WHERE [file_id] = 1;";
		#				#$command = "sqlcmd -S. -Q `"$query`"";
		#				#$output = Invoke-Expression $command;
		#				
		#				return "<TODO...>";
		#			}
		#		}
		#		
		#		Facet "TempDbLogsPath" -ExpectChildKeyValue "SQLServerDefaultDirectories.TempDbLogsPath" -UsesBuild {
		#			Test {
		#				$instanceName = $PVContext.CurrentKeyValue;
		#				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
		#					return "";
		#				}
		#				
		#				return "<TODO...>";
		#			}
		#		}		
		
		Build {
			$sqlServerInstance = $PVContext.CurrentSqlInstance;
			$matched = $PVContext.Matched;
			
			if (-not ($matched)) {
				$currentInstances = $PVContext.GetSurfaceState("InstallationInstances");
				if ($null -eq $currentInstances) {
					$currentInstances = @();
				}
				
				if ($currentInstances -notcontains $sqlServerInstance) {
					$currentInstances += $sqlServerInstance
				}
				
				$PVContext.SetSurfaceState("InstallationInstances", $currentInstances);
			}
		}
		
		Deploy {
			$currentInstances = $PVContext.GetSurfaceState("InstallationInstances");
			
			foreach ($instanceKey in $currentInstances) {
				$version = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.Version");
				$sqlExePathKey = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.SqlExePath");
				$mediaLocation = $PVResources.GetSqlSetupExe($sqlExePathKey);
				$features = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.Features");
				
				# vNEXT: if the $sqlExePathKey endsWith .iso ... then, mount the iso and then return the path to the iso's setup.exe... 
				# https://overachieverllc.atlassian.net/browse/PRO-98
				if (-not (Test-Path $mediaLocation)) {
					throw "Specified [SqlExePath] for SQL Server Instance [$instanceKey] is NOT valid and/or the path could not be located.";
				}
				
				$strictInstallOnly = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.StrictInstallOnly");
				
				$settings = @{};
				$settings["Collation"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.Collation");
				$settings["FileStreamLevel"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.FileStreamLevel");
				$settings["InstantFileInit"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.InstantFileInit");
				$settings["NamedPipesEnabled"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.NamedPipesEnabled");
				$settings["TcpEnabled"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.TcpEnabled");
				$settings["SQLAuthEnabled"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.SecuritySetup.EnableSqlAuth");
				$settings["SaPassword"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.SecuritySetup.SaPassword");
				
				[string[]]$membersOfSysAdmin = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.SecuritySetup.MembersOfSysAdmin");
				$addCurrent = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.SecuritySetup.AddCurrentUserAsAdmin");
				if ($addCurrent) {
					$current = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
					if ($membersOfSysAdmin -notcontains $current) {
						$membersOfSysAdmin += $current;
					}
				}
				
				$installDirs = @{};
				$installDirs["InstallDirectory"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.InstallDirectory");
				$installDirs["InstallSharedDirectory"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.InstallSharedDirectory");
				$installDirs["InstallSharedWowDirectory"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.InstallSharedWowDirectory");
				
				$serviceAccounts = @{};
				$serviceAccounts["SqlServiceAccountName"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.ServiceAccounts.SqlServiceAccountName");
				$serviceAccounts["SqlServiceAccountPassword"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.ServiceAccounts.SqlServiceAccountPassword");
				$serviceAccounts["AgentServiceAccountName"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.ServiceAccounts.AgentServiceAccountName");
				$serviceAccounts["AgentServiceAccountPassword"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.ServiceAccounts.AgentServiceAccountPassword");
				$serviceAccounts["FullTextServiceAccount"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.ServiceAccounts.FullTextServiceAccount");
				$serviceAccounts["FullTextServicePassword"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.ServiceAccounts.FullTextServicePassword");
				
				$sqlDirectories = @{};
				$sqlDirectories["InstallSqlDataPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.SqlServerDefaultDirectories.InstallSqlDataDir");
				$sqlDirectories["SqlDataPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.SqlServerDefaultDirectories.SqlDataPath");
				$sqlDirectories["SqlLogsPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.SqlServerDefaultDirectories.SqlLogsPath");
				$sqlDirectories["SqlBackupsPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.SqlServerDefaultDirectories.SqlBackupsPath");
				$sqlDirectories["TempDbPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.SqlServerDefaultDirectories.TempDbPath");
				$sqlDirectories["TempDbLogsPath"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.SqlServerDefaultDirectories.TempDbLogsPath");
				
				$tempDbDetails = @{};
				$tempDbDetails["SqlTempDbFileCount"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.SqlTempDbFileCount");
				$tempDbDetails["SqlTempDbFileSize"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.SqlTempDbFileSize");
				$tempDbDetails["SqlTempDbFileGrowth"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.SqlTempDbFileGrowth");
				$tempDbDetails["SqlTempDbLogFileSize"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.SqlTempDbLogFileSize");
				$tempDbDetails["SqlTempDbLogFileGrowth"] = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.SqlTempDbLogFileGrowth");
				
				$licenseKey = $PVConfig.GetValue("SqlServerInstallation.$instanceKey.Setup.LicenseKey");
				
				try {
					
					$PVContext.WriteLog("Starting Installation of SQL Server.", "Important");
					Install-SqlServer `
						  -Version $version `
						  -StrictInstallOnly:$strictInstallOnly `
						  -InstanceName $instanceKey `
						  -MediaLocation $mediaLocation `
						  -Features $features `
						  -Settings $settings `
						  -SysAdminMembers $membersOfSysAdmin `
						  -InstallationDirectories $installDirs `
						  -ServiceAccounts $serviceAccounts `
						  -SqlDirectories $sqlDirectories `
						  -SqlTempDbDirectives $tempDbDetails `
						  -LicenseKey $licenseKey;
					
					$PVContext.WriteLog("SQL Server Installation Complete.", "Important");
				}
				catch {
					$PVContext.WriteLog("SQL Server Installation Failure: $_ `r`t$($_.ScriptStackTrace) ", "Critical");
				}
			}
		}
	}
}