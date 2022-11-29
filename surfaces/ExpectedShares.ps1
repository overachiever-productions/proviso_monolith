Set-StrictMode -Version 1.0;

Surface ExpectedShares -Target "ExpectedShares" {
	
	Assertions {
		Assert-HostIsWindows;
		Assert-UserIsAdministrator;
		
		# TODO: I SHOULD be able to use the Assert-ConfigIsStrict helper... but... there's no real way, currently, to get hostname details in there.
		# 		MAYBE it'd make sense to add those as some sort of token? 
		#Assert-ConfigIsStrict -FailureMessage "Current Host-Name of [$([System.Net.Dns]::GetHostName())] does NOT equal config/target Host-Name of [$($PVConfig.GetValue("Host.TargetServer"))]. Proviso will NOT evaluate or configure SHARES on systems where Host/TargetServer names do NOT match.";
		Assert "Config Is -Strict" {
			$targetHostName = $PVConfig.GetValue("Host.TargetServer");
			$currentHostName = [System.Net.Dns]::GetHostName();
			if ($targetHostName -ne $currentHostName) {
				throw "Current Host-Name of [$([System.Net.Dns]::GetHostName())] does NOT equal config/target Host-Name of [$($PVConfig.GetValue("Host.TargetServer"))]. Proviso will NOT evaluate or configure SHARES on systems where Host/TargetServer names do NOT match.";
			}
		}
	}
	
	Aspect -IterateScope {
		Facet "DirectoryExists" -Key "SourceDirectory" -Expect $true {
			Test {
				$targetDirectory = $PVContext.CurrentConfigKeyValue;
				
				return Test-Path $targetDirectory;
			}
			Configure {
				$currentKey = $PVContext.CurrentObjectName;
				$targetDirectory = $PVConfig.GetValue("ExpectedShares.$currentKey.SourceDirectory");
				
				Mount-Directory -Path $targetDirectory;
			}
		}
		
		Facet "IsShared" -Key "ShareName" -Expect $true {
			Test {
				$currentKey = $PVContext.CurrentObjectName;
				$shareName = $PVConfig.GetValue("ExpectedShares.$currentKey.ShareName");
				$targetDirectory = $PVConfig.GetValue("ExpectedShares.$currentKey.SourceDirectory");
				
				$smbShare = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue;
				if ($smbShare) {
					if ($smbShare.Path -eq $targetDirectory) {
						return $true;
					}
				}
				
				return $false;
			}
			Configure {
				$currentKey = $PVContext.CurrentObjectName;
				$shareName = $PVConfig.GetValue("ExpectedShares.$currentKey.ShareName");
				$targetDirectory = $PVConfig.GetValue("ExpectedShares.$currentKey.SourceDirectory");
				
				try {
					New-SmbShare -Name $shareName -Path $targetDirectory | Out-Null;
				}
				catch {
					throw "Exception creating share [$shareName] against directory [$targetDirectory]: $_ `r`t$($_.ScriptStackTrace) ";
				}
				
				$PVContext.WriteLog("Created share [$shareName] against directory [$targetDirectory].", "Verbose");
			}
		}
		
		Facet "ReadOnlyPermsFor" -Key "ReadOnlyAccess" {
			Expect {
				$currentKey = $PVContext.CurrentObjectName;
				$readOnlyUsers = $PVConfig.GetValue("ExpectedShares.$currentKey.ReadOnlyAccess");
				
				if ($readOnlyUsers.Count -eq 0) {
					return "<EMPTY>";
				}
				
				return $true;
			}
			Test {
				$currentKey = $PVContext.CurrentObjectName;
				$shareName = $PVConfig.GetValue("ExpectedShares.$currentKey.ShareName");
				$smbShare = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue;
				
				if (-not $smbShare) {
					return "";
				}
				
				$readOnlyUsers = $PVConfig.GetValue("ExpectedShares.$currentKey.ReadOnlyAccess");
				if ($readOnlyUsers.Count -eq 0) {
					return "<EMPTY>" # no read-only users specified so ... we're set/done... 
				}
				
				$readOnlyPerms = Get-SmbShareAccess -Name ($smbShare.Name) | Where-Object {
					($_.AccessRight -eq "Read") -and ($_.AccessControlType -eq "Allow");
				} | Select-Object -Property AccountName;
				
				foreach ($reader in $readOnlyUsers) {
					if ($reader -notin $readOnlyPerms.AccountName) {
						return $false;
					}
				}
				
				return $true;
			}
			Configure {
				$currentKey = $PVContext.CurrentObjectName;
				$shareName = $PVConfig.GetValue("ExpectedShares.$currentKey.ShareName");
				$smbShare = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue;
				
				if (-not $smbShare) {
					return ""; # must've, somehow, failed creation (as a share)... 
				}
				
				$readOnlyUsers = $PVConfig.GetValue("ExpectedShares.$currentKey.ReadOnlyAccess");
				foreach ($reader in $readOnlyUsers) {
					Grant-SmbShareAccess -Name $shareName -AccountName $reader -AccessRight Read -Force | Out-Null;
				}
			}
		}
		
		Facet "ReadWritePermsFor" -Key "ReadWriteAccess" {
			Expect {
				$currentKey = $PVContext.CurrentObjectName;
				$readWriteUsers = $PVConfig.GetValue("ExpectedShares.$currentKey.ReadWriteAccess");
				
				if ($readWriteUsers.Count -eq 0) {
					return "<EMPTY>";
				}
				
				return $true;
			}
			Test {
				$currentKey = $PVContext.CurrentObjectName;
				$shareName = $PVConfig.GetValue("ExpectedShares.$currentKey.ShareName");
				$smbShare = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue;
				
				if (-not $smbShare) {
					return "";
				}
				
				$readWriteUsers = $PVConfig.GetValue("ExpectedShares.$currentKey.ReadWriteAccess");
				if ($readWriteUsers.Count -eq 0) {
					return "<EMPTY>"; # no users to grant full perms... so, we're done. 
				}
				
				$fullPerms = Get-SmbShareAccess -Name ($smbShare.Name) | Where-Object {
					($_.AccessRight -eq "Full") -and ($_.AccessControlType -eq "Allow");
				} | Select-Object -Property AccountName;
				
				foreach($readWriter in $readWriteUsers) {
					if ($readWriter -notin $fullPerms.AccountName) {
						return $false;
					}
				}
				
				return $true;
			}
			Configure {
				$currentKey = $PVContext.CurrentObjectName;
				$shareName = $PVConfig.GetValue("ExpectedShares.$currentKey.ShareName");
				$smbShare = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue;
				
				if (-not $smbShare) {
					return ""; # must've, somehow, failed creation (as a share)... 
				}
				
				$readWriteUsers = $PVConfig.GetValue("ExpectedShares.$currentKey.ReadWriteAccess");
				foreach ($fullUser in $readWriteUsers) {
					Grant-SmbShareAccess -Name $shareName -AccountName $fullUser -AccessRight Full -Force | Out-Null;
				}
			}
		}
	}
}