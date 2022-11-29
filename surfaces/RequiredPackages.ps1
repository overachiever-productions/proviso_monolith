Set-StrictMode -Version 1.0;

Surface "RequiredPackages" -Target "Host" {
	
	Assertions {
		Assert-UserIsAdministrator;
		Assert-HostIsWindows #-Server;
		Assert-ProvisoResourcesRootDefined;
	}
	
	Aspect -Scope "RequiredPackages" {
#		Facet "WSFCRequired" -Key "WsfcComponents" -ExpectKeyValue -RequiresReboot {
#			Test {
#				$installed = (Get-WindowsFeature -Name Failover-Clustering).InstallState;
#				$PVContext.SetSurfaceState("WSFC_Installed", $installed);
#				
#				# TODO: instead of showing true/false for WSFCRequired in the Summary/Summarize-output... show INSTALLED, AVAILABLE, PENDING or whatever. 
#				# 		this'll require a tweak to the Expect{} block as well. i.e., it' can't show 'true' and expect that to match 'installed', 'available', etc. 
#				if ($installed -eq "Installed") {
#					return $true;
#				}
#				
#				return $false;
#			}
#			Configure {
#				
#				if($PVContext.CurrentConfigKeyValue) {
#					
#					$rebootRequired = Install-WsfcComponents;
#					
#					if ($rebootRequired) {
#						$PVContext.SetRebootRequired("WSFC Component installation requires reboot.");
#					}
#				}
#				else {
#					$installed = $PVContext.GetSurfaceState("WSFC_Installed");
#					if ($installed) {
#						# it's actually, currently, installed ... and the config value is that it doesn't NEED to be installed
#						$PVContext.WriteLog("WSFC Components Installed - but not _REQUIRED_ via Config. Proviso will NOT uninstall WSFC components. Manually use [Uninstall-WindowsFeature Failover-Clustering] if needed.", "Important");
#					}
#				}
#			}
#		}
		
		Facet "NetFXRequired" -Key "NetFxForPre2016InstancesRequired" -ExpectKeyValue {
			Test {
				# check to see if v3.5 is installed: 
				$allInstalled = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |	Get-ItemProperty -name Version, Release -EA 0 | Where-Object {	$_.PSChildName -match '^(?!S)\p{L}' } | Select-Object PSChildName, Version;
				$installed = $allInstalled | Where-Object { $_.PSChildName -eq "v3.5 " };
				
				$PVContext.SetSurfaceState("NetFX35_Installed", $installed);
				
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
#				else {
#					$installed = $PVContext.GetSurfaceState("NetFX35_Installed");
#					if ($installed) {
#						# it's currently installed, but not REQUIRED... 
#						$PVContext.WriteLog(".NET 3.5 is currently installed - but not _REQUIRED_ via Config. Proviso will NOT uninstall.", "Important");
#					}
#				}
			}
		}
		
#		Facet "ADManagementFeaturesForPoshRequired" -ExpectKeyValue "Host.RequiredPackages.AdManagementFeaturesforPowershell6PlusRequired" {
#			Test {
#				$installed = (Get-WindowsFeature RSAT-AD-Powershell).InstallState;
#				$PVContext.SetSurfaceState("ADManagement_Installed", $installed);
#				
#				if ("Installed" -eq $installed) {
#					return $true;
#				}
#				
#				return $false;
#			}
#			
#			Configure {
#				if ($PVConfig.GetValue("Host.RequiredPackages.AdManagementFeaturesforPowershell6PlusRequired")) {
#					Install-WindowsFeature RSAT-AD-Powershell;
#				}
#				else {
#					$installed = $PVContext.GetSurfaceState("ADManagement_Installed");
#					if ("Installed" -eq $installed) {
#						$PVContext.WriteLog("AD Management Features installed - but not _REQUIRED_ via Config. Proviso will NOT uninstall.", "Important");
#					}
#				}
#			}
#		}
	}
}