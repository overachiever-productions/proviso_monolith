Set-StrictMode -Version 1.0;

Surface ExpectedDirectories -Target "ExpectedDirectories" {
	
	Assertions {
		Assert-HostIsWindows;
		
		Assert-UserIsAdministrator;
		
		Assert-SqlServerIsInstalled -AssertOnConfigureOnly -FailureMessage "Directory permissions for SQL Server service accounts can NOT be configured until SQL Server has been installed";
		
		# TODO: make it so I can use the following (with a context-sensitive failure message vs 'having' to use the whole func... )
		# Assert-ConfigIsStrict -FailureMessage
		Assert "Config Is -Strict" {
			$targetHostName = $PVConfig.GetValue("Host.TargetServer");
			$currentHostName = [System.Net.Dns]::GetHostName();
			if ($targetHostName -ne $currentHostName) {
				throw "Current Host-Name of [$currentHostName] does NOT equal config/target Host-Name of [$targetHostName]. Proviso will NOT evaluate or configure DIRECTORIES on systems where Host/TargetServer names do NOT match.";
			}
		}
	}
	
	Aspect {
		Facet "SqlDirExists" -Key "VirtualSqlServerServiceAccessibleDirectories" -ExpectIteratorValue {
			Test {
				$keyValue = $PVContext.CurrentConfigKeyValue;
				
				if (Test-Path -Path $keyValue) {
					return $keyValue;
				}
				
				return "";
			}
			Configure {
				$keyValue = $PVContext.CurrentConfigKeyValue;
				
				Mount-Directory $keyValue;
			}
		}
		
		Facet "SqlDirHasPerms" -Key "VirtualSqlServerServiceAccessibleDirectories" -Expect "FullControl" {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				$installedInstances = Get-ExistingSqlServerInstanceNames;
				
				if ($instanceName -notin $installedInstances) {
					return "";
				}
				
				$directory = $PVContext.CurrentConfigKeyValue;
				
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
				$directory = $PVContext.CurrentConfigKeyValue;
				Mount-Directory $directory;
				
				$instanceName = $PVContext.CurrentSqlInstance;
				$installedInstances = Get-ExistingSqlServerInstanceNames;
				
				if ($instanceName -notin $installedInstances) {
					throw "SQL Server Instance [$instanceName] has not been installed yet.";
				}
				
				$virtualAccountName = Get-SqlServerDefaultServiceAccount -InstanceName $instanceName -AccountType "SqlServiceAccountName";
				Grant-PermissionsToDirectory -TargetDirectory $directory -Account $virtualAccountName;
			}
		}
		
		Facet "RawDirExists" -Key "RawDirectories" -ExpectIteratorValue {
			Test {
				$keyValue = $PVContext.CurrentConfigKeyValue;
				
				if (Test-Path -Path $keyValue) {
					return $keyValue;
				}
				
				return "";
			}
			Configure {
				$keyValue = $PVContext.CurrentConfigKeyValue;
				Mount-Directory $keyValue;
			}
		}
	}
}