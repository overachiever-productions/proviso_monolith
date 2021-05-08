Set-StrictMode -Version 3.0;

# Note: this function arguably violates SRP - but... it's a facade - something to make all of the underlying operations easier/simpler.

function Set-WindowsServerPreferences {
	
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
	param (
		[ValidateNotNullOrEmpty()]
		[string]$TargetVolumeForDvdDrive,
		[switch]$SetWindowsExplorerPreferences = $true,
		[switch]$DisableServerManager = $true,
		[switch]$EnableDiskPerfCounters = $true,
		[switch]$SetPowerConfigToHighPerf = $true,
		[switch]$DisableMonitorTimeout = $false,
		[switch]$Force = $false
	);
	
	process {
		
		# Process directives for DVD move/changes:
		$targetDrive = $TargetVolumeForDvdDrive.Replace(":", "").Replace("\", "") + ":";
		
		$dvdDrive = Get-CimInstance -Class Win32_volume -Filter 'DriveType = 5';
		if ($dvdDrive) {
			$drive = $dvdDrive | Select-Object DriveLetter;
			$driveLetter = $drive.DriveLetter;
			
			if ($driveLetter -ne $targetDrive) {
				if ($Force -or $PSCmdlet.ShouldProcess("Set-WindowsServerPreferences", "Move-DvdDriveToVolume")) {
					
					Set-CimInstance -InputObject $dvdDrive -Arguments @{
						DriveLetter = $targetDrive
					} | Out-Null;
					
					Write-Host "DVD Drive moved to $targetDrive\ ...";
				}
			}
		}
		
		#Explorer Prefs
		if ($SetWindowsExplorerPreferences) {
			
			$launchTo = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "LaunchTo";
			$hideExt = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "HideFileExt";
			$showHidden = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "Hidden";
			
			if (($launchTo.LaunchTo -ne 1) -or ($hideExt.HideFileExt -ne 0) -or ($showHidden.Hidden -ne 1)) {
				if ($Force -or $PSCmdlet.ShouldProcess("Set-WindowsServerPreferences", "Set-WindowsExplorerPreferences")) {
					# open to "This PC" vs "Quick Acces" 
					Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "LaunchTo" -Value 1; # 2 is "quick access"
					
					# Show Extensions and System Files:
					Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "HideFileExt" -Value 0; # 0 = false - don't hide... 
					Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "Hidden" -Value 1; # 2 = don't show (go figure)
					
					# Make the 2x changes above 'take' by restarting Explorer (seriously). (Pretty violent, BUT, Windows Explorer is somehow doing SOMETHING like this (but not quite as drastic) via the GUI changes.)
					Stop-Process -ProcessName Explorer -Force;
				}
			}
		}
		
		# server manaager: 
		if ($DisableServerManager) {
			$enabled = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\" -Name "DoNotOpenServerManagerAtLogon"
			
			if ($enabled.DoNotOpenServerManagerAtLogon -ne 0) {
				if ($Force -or $PSCmdlet.ShouldProcess("Set-WindowsServerPreferences", "Disable-ServerManagerAtStartup")) {
					Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\" -Name "DoNotOpenServerManagerAtLogon" -Value 0; # yeah, no idea why 0 vs 1... but... whatever.
				}
			}
		}
		
		# disk perf:
		if ($EnableDiskPerfCounters) {
			if ($Force -or $PSCmdlet.ShouldProcess("Set-WindowsServerPreferences", "Enable-DiskPerfCounters")) {
				Invoke-Expression "diskperf -Y" | Out-Null;
				# There's no real way to detect if counters are on or off. i.e., if you run > DiskPerf ... it doesn't give you current status - just a blurb about how they're off/on by demand (e.g., compare the output for "DiskPerf" on a system after running both DiskPerf -Y and DiskPerf -N - it's identical.
			}
		}
		
		# power config:
		if ($SetPowerConfigToHighPerf) {
			$current = powercfg -GETACTIVESCHEME;
			
			if (!($current -contains "(High performance)")) {
				if ($Force -or $PSCmdlet.ShouldProcess("Set-WindowsServerPreferences", "Set-PowerConfigurationToHighPerf")) {
					powercfg -SETACTIVE SCHEME_MIN;
				}
			}
		}
		
		# monitor timeouts: 
		if ($DisableMonitorTimeout) {
			if ($Force -or $PSCmdlet.ShouldProcess("Set-WindowsServerPreferences", "")) {
				powercfg -CHANGE -MONITOR-TIMEOUT-AC 0; # disable monitor timeouts on virtual machines... 
				# MKC: not 'bothering' to make this idempotent. It'll mostly be enabled in my lab and ... it's a wee bit (apparently) of a pain in the butt to detect... 
			}
		}
	};
}