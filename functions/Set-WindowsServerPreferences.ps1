Set-StrictMode -Version 1.0;

# Note: this function arguably violates SRP - but... it's a convenience/shorthand function - or a facade - something to 
#		make all of the underlying operations easier/simpler.

function Set-WindowsServerPreferences {
	
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
	param (
		[ValidateNotNullOrEmpty()]
		[string]$TargetVolumeForDvdDrive,
		[switch]$SetWindowsExplorerPreferences = $true,
		[switch]$DisableServerManager = $true,
		[switch]$EnableDiskPerfCounters = $true,
		[switch]$SetPowerConfigToHighPerf = $true,
		[switch]$Force = $false
	);
	
	begin {

	};
	
	process {
		
		# Process directives for DVD move/changes:
		$targetDrive = $null;
		
		if (![string]::IsNullOrEmpty($TargetVolumeForDvdDrive)) {
			$targetDrive = $TargetVolumeForDvdDrive.Replace(":", "").Replace("\", "") + ":";
			
			$currentDvdDrive = Get-CimInstance -Class Win32_volume -Filter 'DriveType = 5';
			
			if (!$currentDvdDrive) {
				throw "Cannot move DVD Drive to Volume $targetDrive - no DVD Drive found on Server.";
			}
			
			$currentDriveLetter = $currentDvdDrive.DriveLetter;
			
			if ($targetDrive -eq $currentDriveLetter) {
				Write-Host "Dvd Drive already set to $targetDrive (no changes will be made).";
				$targetDrive = $null;
			}
		}
		
		if ($Force -or $PSCmdlet.ShouldProcess("Set-WindowsServerPreferences", "Move-DvdDriveToVolume")) {
			$target = "$($TargetVolumeForDvdDrive):"
			
			$dvdDrive = Get-CimInstance -Class Win32_volume -Filter 'DriveType = 5';
			if ($dvdDrive) {
				
				$drive = $dvdDrive | Select-Object DriveLetter;
				$driveLetter = $drive.DriveLetter;
				
				if ($driveLetter -ne $target) {
					Set-CimInstance -InputObject $dvdDrive -Arguments @{ DriveLetter = $target } | Out-Null;
					
					Write-Host "DVD Drive moved to $target\ ...";
				}
			}
		}
		
		#Explorer Prefs
		if ($Force -or $PSCmdlet.ShouldProcess("Set-WindowsServerPreferences", "Set-WindowsExplorerPreferences")) {
			# TODO: Idempotentize - i.e., if any of these values have already been set, don't change them. And if NO changes have been made, don't restart Explorer...
			
			# open to "This PC" vs "Quick Acces" 
			Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "LaunchTo" -Value 1; # 2 is "quick access"
			
			# Show Extensions and System Files:
			Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "HideFileExt" -Value 0; # 0 = false - don't hide... 
			Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "Hidden" -Value 1; # 2 = don't show (go figure)
			
			# Make the 2x changes above 'take' by restarting Explorer (seriously). (Pretty violent, BUT, Windows Explorer is somehow doing SOMETHING like this (but not quite as drastic) via the GUI changes.)
			Stop-Process -ProcessName Explorer -Force;
		}
		
		# server manaager: 
		if ($Force -or $PSCmdlet.ShouldProcess("Set-WindowsServerPreferences", "Disable-ServerManagerAtStartup")) {
			Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\" -Name "DoNotOpenServerManagerAtLogon" -Value 0; # yeah, no idea why 0 vs 1... but... whatever.
		}
		
		# disk perf:
		if ($Force -or $PSCmdlet.ShouldProcess("Set-WindowsServerPreferences", "Enable-DiskPerfCounters")) {
			Invoke-Expression "diskperf -Y";
		}
		
		
		# power config:
		if ($Force -or $PSCmdlet.ShouldProcess("Set-WindowsServerPreferences", "Set-PowerConfigurationToHighPerf")) {
			powercfg -SETACTIVE SCHEME_MIN;
			powercfg -CHANGE -MONITOR-TIMEOUT-AC 0; # disable monitor timeouts on virtual machines... 
		}
		
	};
	
	end {
		
	};
	
}