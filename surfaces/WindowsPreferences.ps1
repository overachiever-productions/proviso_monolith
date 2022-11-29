Set-StrictMode -Version 1.0;

Surface "WindowsPreferences" -Target "Host" {
	
	Assertions {
		Assert-UserIsAdministrator;
		
		Assert-HostIsWindows;
	}
	
	Aspect -Scope "WindowsPreferences" {
		Facet "DvdDriveToZ" -Key "DvdDriveToZ" {
			Expect {
				$dvdDrive = Get-CimInstance -Class Win32_volume -Filter 'DriveType = 5';
				if ($dvdDrive) {
					$output = $PVConfig.GetValue("Host.WindowsPreferences.DvdDriveToZ");
					if ($output) {
						return "Z:"
					}
					
					return $false;
				}
				
				return "<EMPTY>";
			}
			Test {
				$dvdDrive = Get-CimInstance -Class Win32_volume -Filter 'DriveType = 5';
				if ($dvdDrive) {
					$drive = $dvdDrive | Select-Object DriveLetter;
					$driveLetter = $drive.DriveLetter;
					
					return $driveLetter;
				}
				
				return "<EMPTY>";
			}
			Configure {
				$moveToZ = $PVContext.CurrentConfigKeyValue;
				
				if ($moveToZ) {
					$dvdDrive = Get-CimInstance -Class Win32_volume -Filter 'DriveType = 5';
					
					if ($dvdDrive) {
						$drive = $dvdDrive | Select-Object DriveLetter;
						$driveLetter = $drive.DriveLetter;
						
						if ($driveLetter -ne "Z") {
							Set-CimInstance -InputObject $dvdDrive -Property @{
								DriveLetter = "Z:"
							} | Out-Null;
							
							$PVContext.WriteLog("DVD Drive moved to Z:\ ... ", "Verbose");
						}
					}
					else {
						$PVContext.WriteLog("No DVD Drive found to set to Drive Z.", "Verbose");
					}
				}
				else {
					$PVContext.WriteLog("Config Setting [Host.WindowsPreferences.DvdDriveToZ] set to `$false - but DVD Drive is already Set to Z. Proviso will NOT 'undo' this setting.", "Important");
				}
			}
		}
		
		Facet "OptimizeWindowsExplorer" -Key "OptimizeExplorer" -ExpectKeyValue {
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
				$optimize = $PVContext.CurrentConfigKeyValue;
				
				if ($optimize) {
					Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "LaunchTo" -Value 1; # 2 is "quick access"
					Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "HideFileExt" -Value 0; # 0 = false - don't hide... 
					Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "Hidden" -Value 1; # 2 = don't show (go figure)
					
					# Make the changes above 'take' by restarting Explorer (seriously). (Pretty violent, BUT, Windows Explorer is somehow doing SOMETHING like this (but not quite as drastic) via the GUI changes.)
					Stop-Process -ProcessName Explorer -Force;
					$PVContext.WriteLog("Explorer Optimized...", "Verbose");
				}
				else {
					Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "LaunchTo" -Value 2;
					Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "HideFileExt" -Value 1;
					Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "Hidden" -Value 2;
					
					# Make the changes above 'take' by restarting Explorer (seriously). (Pretty violent, BUT, Windows Explorer is somehow doing SOMETHING like this (but not quite as drastic) via the GUI changes.)
					Stop-Process -ProcessName Explorer -Force;
					$PVContext.WriteLog("Explorer UN-Optimized...", "Verbose");
				}
			}
		}
		
		Facet "DisableServerManager" -Key "DisableServerManagerOnLaunch" -ExpectKeyValue {
			Test {
				$enabled = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\" -Name "DoNotOpenServerManagerAtLogon" -ErrorAction SilentlyContinue;
				
				if ($enabled) {
					if ($enabled.DoNotOpenServerManagerAtLogon -eq 0) {
						# NOTE: MS is drunk here. 0 = ... true (somehow).
						return $true;
					}
				}
				
				return $false;
			}
			Configure {
				#$disable = $PVContext.GetValue("Host.WindowsPreferences.DisableServerManagerOnLaunch");
				$disable = $PVContext.CurrentConfigKeyValue;
				
				if ($disable) {
					Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\" -Name "DoNotOpenServerManagerAtLogon" -Value 0; # yeah, no idea why 0 vs 1... but... whatever.
				}
				else {
					# uh... un-disable: 
					Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\" -Name "DoNotOpenServerManagerAtLogon" -Value 1; # yeah, no idea why 0 vs 1... but... whatever.
				}
			}
		}
		
		Facet "HighPerfPowerConfig" -Key "SetPowerConfigHigh" -ExpectKeyValue {
			Test {
				$current = powercfg -GETACTIVESCHEME;
				if (!($current -contains "(High performance)")) {
					return $true;
				}
				return $false;
			}
			Configure {
				#$config = $PVConfig.GetValue("Host.WindowsPreferences.SetPowerConfigHigh");
				$config = $PVContext.CurrentConfigKeyValue;
				
				if ($config) {
					Invoke-Expression "powercfg -SETACTIVE SCHEME_MIN;" | Out-Null;
					$PVContext.WriteLog("Power Configuration set to High-Perf...", "Verbose");
				}
				else {
					$PVContext.WriteLog("Config value for [Host.WindowsPreferences.SetPowerConfigHigh] equals `$false - but Power Config is already set to High. Proviso will NOT 'undo' this configuration. Make change manually if/as needed.", "Important");
				}
			}
		}
		
		Facet "DisableMonitorTimeout" -Key "DisableMonitorTimeout" -ExpectKeyValue {
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
				#$disable = $PVConfig.GetValue("Host.WindowsPreferences.DisableMonitorTimeout");
				$disable = $PVContext.CurrentConfigKeyValue;
				
				if ($disable) {
					Invoke-Expression "powercfg -CHANGE -MONITOR-TIMEOUT-AC 0;" | Out-Null;
					$PVContext.WriteLog("Monitor Timeout Disabled on AC Power...", "Verbose");
				}
				else {
					Invoke-Expression "powercfg -CHANGE -MONITOR-TIMEOUT-AC 10;" | Out-Null;
					$PVContext.WriteLog("Monitor Timeout on AC Power set to 10 minutes.", "Verbose");
				}
			}
		}
		
		Facet "EnableDiskPerfCounters" -Key "EnableDiskPerfCounters" -ExpectKeyValue {
			Test {
				$state = diskperf;
				if ($state -match "[(Both)(are automatically enabled)]{2}") {
					return $true;
				}
				return $false;
			}
			Configure {
				#$enable = $PVConfig.GetValue("Host.WindowsPreferences.EnableDiskPerfCounters");
				$enable = $PVContext.CurrentConfigKeyValue;
				
				if ($enable) {
					Invoke-Expression "diskperf -Y" | Out-Null;
					$PVContext.WriteLog("Disk Perf Counters enabled...", "Verbose");
				}
				else {
					Invoke-Expression "diskperf -N" | Out-Null;
					$PVContext.WriteLog("Disk Perf Counters DISABLED...", "Verbose");
				}
			}
		}
	}
}