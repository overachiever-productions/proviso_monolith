Set-StrictMode -Version 1.0;

<#

Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;

#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-TestingSurface;
With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-ExpectedDirectories;

Summarize -Latest;

#>

Surface ExpectedDirectories -For -Key "ExpectedDirectories" {
	
	Assertions {
		Assert-HostIsWindows;
		
		Assert-UserIsAdministrator;
		
#		Assert "Config Is -Strict" {
#			$targetHostName = $PVConfig.GetValue("Host.TargetServer");
#			$currentHostName = [System.Net.Dns]::GetHostName();
#			if ($targetHostName -ne $currentHostName) {
#				throw "Current Host-Name of [$currentHostName] does NOT equal config/target Host-Name of [$targetHostName]. Proviso will NOT evaluate or configure DIRECTORIES on systems where Host/TargetServer names do NOT match.";
#			}
#		}
	}
	
	Compound-Scope -GroupKey "ExpectedDirectories.*" {
		Facet "SqlDirExists" -CompoundValueKey "VirtualSqlServerServiceAccessibleDirectories" -ExpectValueForCompoundKey {
			Test {
				$keyValue = $PVContext.CurrentChildKeyValue;
				
				if (Test-Path -Path $keyValue) {
					return $keyValue;
				}
				
				return "";
			}
			Configure {
				$keyValue = $PVContext.CurrentChildKeyValue;
				
				Mount-Directory $keyValue;
			}
		}
		
		Facet "SqlDirHasPerms" -CompoundValueKey "VirtualSqlServerServiceAccessibleDirectories" -Expect "FullControl" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$installedInstances = Get-ExistingSqlServerInstanceNames;
				
				if ($instanceName -notin $installedInstances) {
					return "";
				}
				
				$directory = $PVContext.CurrentChildKeyValue;
				
				$virtualAccountName = Get-SqlServerDefaultServiceAccount -InstanceName $instanceName -AccountType "SqlServiceAccountName";
				$aclSummary = Get-DirectoryPermissionsSummary -Directory $directory | Where-Object { $_.Account -eq $virtualAccountName };
				
				if ($null -eq $aclSummary) {
					return "";
				}
				
				if ($aclSummary.Type -ne "Allow") {
					return $aclSummary.Type;
				}
				
				return $aclSummary.Access;
			}
			Configure {
				$directory = $PVContext.CurrentChildKeyValue;
				Mount-Directory $directory;
				
				$instanceName = $PVContext.CurrentKeyValue;
				$installedInstances = Get-ExistingSqlServerInstanceNames;
				
				if ($instanceName -notin $installedInstances) {
					throw "SQL Server Instance [$instanceName] has not been installed yet.";
				}
				
				$virtualAccountName = Get-SqlServerDefaultServiceAccount -InstanceName $instanceName -AccountType "SqlServiceAccountName";
				Grant-SqlServicePermissionsToDirectory -TargetDirectory $directory -SqlServiceAccount $virtualAccountName;
			}
		}
		
		Facet "RawDirExists" -CompoundValueKey "RawDirectories" -ExpectValueForCompoundKey {
			Test {
				$keyValue = $PVContext.CurrentChildKeyValue;
				
				if (Test-Path -Path $keyValue) {
					return $keyValue;
				}
				
				return "";
			}
			Configure {
				$keyValue = $PVContext.CurrentChildKeyValue;
				Mount-Directory $keyValue;
			}
		}
	}
}