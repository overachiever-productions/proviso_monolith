Set-StrictMode -Version 1.0;

<#

Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;

Assign -ProvisoRoot "\\storage\Lab\proviso";

#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-SqlInstallation;
With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Configure-SqlInstallation;
#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Configure-TestingSurface;

Summarize -Latest;

# TODO:
   figure out which directives to NUKE/REMOVE based up on VERSION of SQL Server being installed. 
	Also... pretty sure that means I need to pass the $Version in to Install-SqlServer (er... well, yeah: duh: i do)

#>

Surface SqlInstallation {
	Assertions {
		
	}
		
	Aspect -Scope "SQLServerInstallation.*" {
		Facet "InstanceExists" -ExpectCurrentKeyValue {
			Test {
				$instanceKey = $PVContext.CurrentKeyValue;
				$installedInstances = Get-ExistingSqlServerInstanceNames;
				
				if ($instanceKey -in $installedInstances) {
					$PVContext.AddSurfaceState("$instanceKey.Installed", $true);
					return $instanceKey;
				}
				
				$PVContext.AddSurfaceState("$instanceKey.Installed", $false);
				return "";
			}
			Configure {
				$instanceKey = $PVContext.CurrentKeyValue;
				
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
		
		# TODO: re-implement equivalent of -IgnoreOnEmptyConfig
		Facet "Version" -ExpectChildKeyValue "Setup.Version" -UsesBuild  {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
		
				return (Get-SqlServerInstanceDetailsFromRegistry -InstanceName $instanceName -Detail "VersionName");
			}
		}
		
		# TODO: re-implement equivalent of -IgnoreOnEmptyConfig
		Facet "Edition" -ExpectChildKeyValue "Setup.Edition" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
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
		
		Facet "Collation" -ExpectChildKeyValue "Setup.Collation" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
				
				return (Get-SqlServerInstanceDetailsFromRegistry -InstanceName $instanceName -Detail "Collation");
			}
		}
		
		Facet "SqlServiceAccount" -ExpectChildKeyValue "ServiceAccounts.SqlServiceAccountName" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
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
		
		Facet "SqlAgentAccount" -ExpectChildKeyValue "ServiceAccounts.AgentServiceAccountName" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
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
		
		Facet "AllowSqlAuth" -ExpectChildKeyValue "SecuritySetup.EnableSqlAuth" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
				
				return Get-SqlServerInstanceDetailsFromRegistry -InstanceName $instanceName -Detail "MixedMode";
			}
		}
		
		# members of sys-admin... 
		
		Facet "DataPath" -ExpectChildKeyValue "SQLServerDefaultDirectories.SqlDataPath" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
				
				return Get-SqlServerInstanceDetailsFromRegistry -InstanceName $instanceName -Detail "DefaultData";
			}
		}
		
		Facet "LogsPath" -ExpectChildKeyValue "SQLServerDefaultDirectories.SqlLogsPath" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
				
				return Get-SqlServerInstanceDetailsFromRegistry -InstanceName $instanceName -Detail "DefaultLog";
			}
		}
		
		Facet "BackupsPath" -ExpectChildKeyValue "SQLServerDefaultDirectories.SqlBackupsPath" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				if (-not ($PVContext.GetSurfaceState("$instanceName.Installed"))) {
					return "";
				}
				
				return Get-SqlServerInstanceDetailsFromRegistry -InstanceName $instanceName -Detail "DefaultBackups";
			}
		}
		
		Build {
			
			
			
		}
		
		Deploy {
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
	}
}