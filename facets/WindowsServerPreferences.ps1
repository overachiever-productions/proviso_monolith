Set-StrictMode -Version 1.0;

Facet "WindowsServerPreferences" -For -Key "Host.WindowsPreferences" {
	
	Assertions {
		Assert -Is "Adminstrator" -FailureMessage "Current User is not a Member of the Administrators Group" {
			$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
			$admins = Get-LocalGroupMember -Group Administrators | Select-Object -Property "Name";
			
			if ($admins.Name -contains $currentUser) {
				return $true;
			}
			
			return $false;
		}
		
		Assert -Is "WindowsServer" {
			$os = (Get-ChildItem -Path Env:\POWERSHELL_DISTRIBUTION_CHANNEL).Value;
			if ($os -like "*Windows Server*") {
				return $true;
			}
			return $false;
		}
		
	}
	
	Definitions {
		
		Definition "DvdDriveToZ" -For -Key "Host.WindowsPreferences.DvdDriveToZ" {
			Test {
				$dvdDrive = Get-CimInstance -Class Win32_volume -Filter 'DriveType = 5';
				if ($dvdDrive) {
					$drive = $dvdDrive | Select-Object DriveLetter;
					$driveLetter = $drive.DriveLetter;
					
					$PVContext.AddFacetState("DvdDrive", $dvdDrive);
					
					return $driveLetter;
				}
			}
			
			Configure {
				$dvdDrive = $PVContext.GetFacetState("DvdDrive");
				if ($dvdDrive) {
					$drive = $dvdDrive | Select-Object DriveLetter;
					$driveLetter = $drive.DriveLetter;
					
					if ($driveLetter -ne "Z") {
						Set-CimInstance -InputObject $dvdDrive -Arguments @{
							DriveLetter = "Z"
						} | Out-Null;
						
						$PVContext.WriteLog("DVD Drive moved to Z:\ ... ", "Verbose");
					}
				}
			}
		}
		
		Definition "OptimizeWindowsExplorer" -For -Key "Host.WindowsPreferences.OptimizeExplorer" {
			Test {
				$key = Get-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\";
				$launchTo = $null;
				$hideExt = $null;
				$showHidden = $null;
				
				$launchTo = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "LaunchTo" -ErrorAction SilentlyContinue;
				$hideExt = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "HideFileExt" -ErrorAction SilentlyContinue;
				$showHidden = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "Hidden" -ErrorAction SilentlyContinue;
				
				if (($launchTo.LaunchTo -ne 1) -or ($hideExt.HideFileExt -ne 0) -or ($showHidden.Hidden -ne 1)) {
					return $false;
				}
				
				return $true;
			}
			Configure {
				Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "LaunchTo" -Value 1; # 2 is "quick access"
				Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "HideFileExt" -Value 0; # 0 = false - don't hide... 
				Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "Hidden" -Value 1; # 2 = don't show (go figure)
				
				# Make the changes above 'take' by restarting Explorer (seriously). (Pretty violent, BUT, Windows Explorer is somehow doing SOMETHING like this (but not quite as drastic) via the GUI changes.)
				Stop-Process -ProcessName Explorer -Force;
			}
		}
		
		Definition "DisableServerManager" -For -Key "Host.WindowsPreferences.DisableServerManagerOnLaunch" {
			Test {
				$enabled = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\" -Name "DoNotOpenServerManagerAtLogon";
				
				if ($enabled.DoNotOpenServerManagerAtLogon -eq 0) { # NOTE: MS is drunk here. 0 = ... true (somehow).
					return $true;
				}
				return $false;
			}
			
			Configure {
				Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\" -Name "DoNotOpenServerManagerAtLogon" -Value 0; # yeah, no idea why 0 vs 1... but... whatever.
			}
		}
		
		Definition "HighPerfPowerConfig" -For -Key "Host.WindowsPreferences.SetPowerConfigHigh" {
			Test {
				$current = powercfg -GETACTIVESCHEME;
				if (!($current -contains "(High performance)")) {
					return $true;
				}
				return $false;
			}
			
			Configure {
				Invoke-Expression "powercfg -SETACTIVE SCHEME_MIN;" | Out-Null;
				$PVContext.WriteLog("Power Configuration set to High-Perf...", "Verbose");
			}
		}
		
		Definition "DisableMonitorTimeout" -For -Key "Host.WindowsPreferences.DisableMonitorTimeout" {
			Test {
				$output = powercfg /Query;
				$block = [regex]::split($output, 'VIDEOIDLE')[1];
				$block = [regex]::split($block, 'Current DC Power Setting')[0];
				$match = [regex]::Match($block, 'AC Power Setting Index: 0x(?<setting>[0-9a-b]{8})');
				if ($match) {
					$setting = $match.Groups["setting"].Value;
					
					if ($setting -eq "00000000") {
						return $true;
					}
				}
				
				return $false;
			}
			
			Configure {
				Invoke-Expression "powercfg -CHANGE -MONITOR-TIMEOUT-AC 0;" | Out-Null;
				$PVContext.WriteLog("Monitor Timeout Disabled on AC Power...", "Verbose");
			}
		}
		
		Definition "EnableDiskPerfCounters" -For -Key "Host.WindowsPreferences.EnableDiskPerfCounters" {
			Test {
				$state = diskperf;
				if ($state -match "[(Both)(are automatically enabled)]{2}") {
					return $true;
				}
				return $false;
			}
			
			Configure {
				Invoke-Expression "diskperf -Y" | Out-Null;
				$PVContext.WriteLog("Disk Perf Counters enabled...", "Verbose");
			}
		}
	}
}