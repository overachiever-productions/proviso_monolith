Set-StrictMode -Version 1.0;

Surface "RequiredPackages" -For -Key "Host.RequiredPackages" {
	
	Assertions {
		
		Assert-UserIsAdministrator;
		
		Assert-HostIsWindows #-Server;
		
		Assert-ProvisoResourcesRootDefined;
	}
	
	Definitions {
		Definition -For "WSFCRequired" -ExpectKeyValue "Host.RequiredPackages.WsfcComponents" -RequiresReboot {
			Test {
				$installed = (Get-WindowsFeature -Name Failover-Clustering).InstallState;
				
				# TODO: figure out how to tweak the 'Expected' to show "Installed" if config is $true
				#   then... show actual state of WSFC components ("Available", "Installed", "Install Pending" etc... in here... )
				if ($installed -eq "Installed") {
					return $true;
				}
				
				return $false;
			}
			
			Configure {
				
				if ($PVConfig.GetValue("Host.RequiredPackages.WsfcComponents")) {
					
					$rebootRequired = Install-WsfcComponents;
					
					if ($rebootRequired) {
						$PVContext.SetRebootRequired("WSFC Component installation requires reboot.");
					}
				}
				else {
					# it's actually, currently, installed ... and the config value is that it doesn't NEED to be installed
					$PVContext.WriteLog("WSFC Components Installed - but not _REQUIRED_ via Config. Proviso will NOT uninstall WSFC components. Manually use [Uninstall-WindowsFeature Failover-Clustering] if needed.", "Important");
				}
			}
		}
		
		Definition -For "NetFXRequired" -ExpectKeyValue "Host.RequiredPackages.NetFxForPre2016InstancesRequired" {
			Test {
				# check to see if v3.5 is installed: 
				$allInstalled = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |	Get-ItemProperty -name Version, Release -EA 0 | Where-Object {	$_.PSChildName -match '^(?!S)\p{L}' } | Select-Object PSChildName, Version;
				$installed = $allInstalled | Where-Object { $_.PSChildName -eq "v3.5 " };
				
				if ($installed) {
					return $true;
				}
				
				return $false;
			}
			
			Configure {
				if ($PVConfig.GetValue("Host.RequiredPackages.NetFxForPre2016InstancesRequired")) {
					$windowsVersion = Get-WindowsServerVersion -Version ([System.Environment]::OSVersion.Version);
					
					Install-NetFx35ForPre2016Instances -WindowsServerVersion $windowsVersion -NetFxSxsRootPath (Join-Path -Path $script:resourcesRoot -ChildPath "binaries\net3.5_sxs");
				}
				else {
					# it's currently installed, but not REQUIRED... 
					$PVContext.WriteLog(".NET 3.5 is currently installed - but not _REQUIRED_ via Config. Proviso will NOT uninstall.", "Important");
				}
			}
		}
		
		Definition "ADManagementFeaturesForPoshRequired" -ExpectKeyValue "Host.RequiredPackages.AdManagementFeaturesforPowershell6PlusRequired" {
			Test {
				$state = (Get-WindowsFeature RSAT-AD-Powershell).InstallState;
				
				if ($state -eq "Installed") {
					return $true;
				}
				
				return $false;
			}
			
			Configure {
				
				if ($PVConfig.GetValue("Host.RequiredPackages.AdManagementFeaturesforPowershell6PlusRequired")) {
					Install-WindowsFeature RSAT-AD-Powershell;
				}
				else {
					$PVContext.WriteLog("AD Management Features installed - but not _REQUIRED_ via Config. Proviso will NOT uninstall.", "Important");
				}
			}
		}
	}
}