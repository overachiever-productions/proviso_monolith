Set-StrictMode -Version 1.0;

<#

Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;

Assign -ProvisoRoot "\\storage\Lab\proviso";

#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-SqlServerInstallation;
With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Provision-SqlServerInstallation;
#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Provision-TestingFacet;

Summarize -Latest;

# PICKUP/NEXT:
	Need to figure out how to handle VALIDATE-ONLY against 'defaults' for SqlServerDirs and SqlServerServiceAccounts... 

# THEN
   figure out which directives to NUKE/REMOVE based up on VERSION of SQL Server being installed. 
	Also... pretty sure that means I need to pass the $Version in to Install-SqlServer (er... well, yeah: duh: i do)

#>

Facet SqlServerInstallation {
	Assertions {
		
	}
		
	Group-Definitions -GroupKey "SQLServerInstallation.*" {
		
		Definition "InstanceExists" -ExpectValueForCurrentKey {
			Test {
				$instanceKey = $PVContext.CurrentKeyValue;
				$installedInstances = Get-ExistingSqlServerInstanceNames;
				
				if ($instanceKey -in $installedInstances) {
					$PVContext.AddFacetState("$instanceKey.Installed", $true);
					return $instanceKey;
				}
				
				$PVContext.AddFacetState("$instanceKey.Installed", $false);
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
					
					$PVContext.WriteLog("Starting Installation of SQL Server.", "Verbose");
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
		
		Definition "Version" -ExpectValueForChildKey "Setup.Version" -ConfiguredBy "InstanceExists" -IgnoreOnEmptyConfig {
			Test {
				if (-not ($PVContext.GetFacetState("$currentKey.Installed"))) {
					return "";
				}
				
			}
		}
		
		Definition "Edition" -ExpectValueForChildKey "Setup.Edition" -ConfiguredBy "InstanceExists" -IgnoreOnEmptyConfig {
			Test {
				if (-not ($PVContext.GetFacetState("$currentKey.Installed"))) {
					return "";
				}
				
			}
		}
		
		Definition "Features" -ExpectValueForChildKey "Setup.Features" -ConfiguredBy "InstanceExists" {
			Test {
				if (-not ($PVContext.GetFacetState("$currentKey.Installed"))) {
					return "";
				}
				
				
			}
		}
		
		Definition "SqlServiceAccount" -ExpectValueForChildKey "ServiceAccounts.SqlServiceAccountName" -ConfiguredBy "InstanceExists" {
			Test {
				if (-not ($PVContext.GetFacetState("$currentKey.Installed"))) {
					return "";
				}
				
			}
		}
		
		Definition "SqlAgentAccount" -ExpectValueForChildKey "ServiceAccounts.AgentServiceAccountName" -ConfiguredBy "InstanceExists" {
			Test {
				if (-not ($PVContext.GetFacetState("$currentKey.Installed"))) {
					return "";
				}
				
			}
		}
		
		Definition "AllowSqlAuth" -ExpectValueForChildKey "SecuritySetup.EnableSqlAuth" -ConfiguredBy "InstanceExists" {
			Test {
				if (-not ($PVContext.GetFacetState("$currentKey.Installed"))) {
					return "";
				}
				
			}
		}
		
		# members of sys-admin... 
		
		Definition "DataPath" -ExpectValueForChildKey "SQLServerDefaultDirectories.SqlDataPath" -ConfiguredBy "InstanceExists" {
			Test {
				if (-not ($PVContext.GetFacetState("$currentKey.Installed"))) {
					return "";
				}
				
			}
		}
		
		Definition "LogsPath" -ExpectValueForChildKey "SQLServerDefaultDirectories.SqlLogsPath" -ConfiguredBy "InstanceExists" {
			Test {
				if (-not ($PVContext.GetFacetState("$currentKey.Installed"))) {
					return "";
				}
				
			}
		}
		
		Definition "BackupsPath" -ExpectValueForChildKey "SQLServerDefaultDirectories.SqlBackupsPath" -ConfiguredBy "InstanceExists" {
			Test {
				if (-not ($PVContext.GetFacetState("$currentKey.Installed"))) {
					return "";
				}
				
			}
		}
		
		Definition "TempDbPath" -ExpectValueForChildKey "SQLServerDefaultDirectories.TempDbPath" -ConfiguredBy "InstanceExists" {
			Test {
				if (-not ($PVContext.GetFacetState("$currentKey.Installed"))) {
					return "";
				}
				
			}
		}
		
		Definition "TempDbLogsPath" -ExpectValueForChildKey "SQLServerDefaultDirectories.TempDbLogsPath" -ConfiguredBy "InstanceExists" {
			Test {
				if (-not ($PVContext.GetFacetState("$currentKey.Installed"))) {
					return "";
				}
				
			}
		}
		
		# etc... 
		
	}
}