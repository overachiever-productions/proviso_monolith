Set-StrictMode -Version 1.0;

<#

Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;

#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-ExpectedShares;
With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Provision-ExpectedShares;

Summarize -Latest;

#>

Surface ExpectedShares {
	
	Assertions {
		Assert-HostIsWindows;
		
		Assert-UserIsAdministrator;
		
		Assert "Config Is -Strict" {
			$targetHostName = $PVConfig.GetValue("Host.TargetServer");
			$currentHostName = [System.Net.Dns]::GetHostName();
			if ($targetHostName -ne $currentHostName) {
				throw "Current Host-Name of [$currentHostName] does NOT equal config/target Host-Name of [$targetHostName]. Proviso will NOT evaluate or configure SHARES on systems where Host/TargetServer names do NOT match.";
			}
		}
	}
	
	Group-Definitions -GroupKey "ExpectedShares.*" {
		Definition "DirectoryExists" -Expect $true {
			Test {
				$currentKey = $PVContext.CurrentKeyValue;
				$targetDirectory = $PVConfig.GetValue("ExpectedShares.$currentKey.SourceDirectory");
				
				return Test-Path $targetDirectory;
			}
			Configure {
				$currentKey = $PVContext.CurrentKeyValue;
				$targetDirectory = $PVConfig.GetValue("ExpectedShares.$currentKey.SourceDirectory");
				
				Mount-Directory -Path $targetDirectory;
			}
		}
		
		Definition "IsShared" -Expect $true {
			Test {
				$currentKey = $PVContext.CurrentKeyValue;
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
				$currentKey = $PVContext.CurrentKeyValue;
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
		
		Definition "ReadOnlyPermsFor" {
			Expect {
				$currentKey = $PVContext.CurrentKeyValue;
				$readOnlyUsers = $PVConfig.GetValue("ExpectedShares.$currentKey.ReadOnlyAccess");
				
				if ($readOnlyUsers.Count -eq 0) {
					return "";
				}
				
				return $true;
			}
			Test {
				$currentKey = $PVContext.CurrentKeyValue;
				$shareName = $PVConfig.GetValue("ExpectedShares.$currentKey.ShareName");
				$smbShare = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue;
				
				if (-not $smbShare) {
					return "";
				}
				
				$readOnlyUsers = $PVConfig.GetValue("ExpectedShares.$currentKey.ReadOnlyAccess");
				if ($readOnlyUsers.Count -eq 0) {
					return $true; # no read-only users specified so ... we're set/done... 
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
				$currentKey = $PVContext.CurrentKeyValue;
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
		
		Definition "ReadWritePermsFor" {
			Expect {
				$currentKey = $PVContext.CurrentKeyValue;
				$readWriteUsers = $PVConfig.GetValue("ExpectedShares.$currentKey.ReadWriteAccess");
				
				if ($readWriteUsers.Count -eq 0) {
					return "";
				}
				
				return $true;
			}
			Test {
				$currentKey = $PVContext.CurrentKeyValue;
				$shareName = $PVConfig.GetValue("ExpectedShares.$currentKey.ShareName");
				$smbShare = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue;
				
				if (-not $smbShare) {
					return "";
				}
				
				$readWriteUsers = $PVConfig.GetValue("ExpectedShares.$currentKey.ReadWriteAccess");
				if ($readWriteUsers.Count -eq 0) {
					return $true; # no users to grant full perms... so, we're done. 
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
				$currentKey = $PVContext.CurrentKeyValue;
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