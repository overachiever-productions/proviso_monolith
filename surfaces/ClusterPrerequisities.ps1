Set-StrictMode -Version 1.0;

Surface "ClusterPrerequisites" -Target "Host" {
	# REFACTOR: might make sense to rename this to ClusterDependencies... 		
	Assertions {
		Assert-UserIsAdministrator;
		Assert-HostIsWindows -Server;
	}
	
	Aspect -Scope "RequiredPackages" {
		Facet "WSFCRequired" -Key "WsfcComponents" -ExpectKeyValue -RequiresReboot {
			Test {
				$installed = (Get-WindowsFeature -Name Failover-Clustering).InstallState;
				$PVContext.SetSurfaceState("WSFC_Installed", $installed);
				
				# TODO: instead of showing true/false for WSFCRequired in the Summary/Summarize-output... show INSTALLED, AVAILABLE, PENDING or whatever. 
				# 		this'll require a tweak to the Expect{} block as well. i.e., it' can't show 'true' and expect that to match 'installed', 'available', etc. 
				if ($installed -eq "Installed") {
					return $true;
				}
				
				return $false;
			}
			Configure {
				
				if ($PVContext.CurrentConfigKeyValue) {
					
					$rebootRequired = Install-WsfcComponents;
					
					if ($rebootRequired) {
						$PVContext.SetRebootRequired("WSFC Component installation requires reboot.");
					}
				}
				else {
					$installed = $PVContext.GetSurfaceState("WSFC_Installed");
					if ($installed) {
						# it's actually, currently, installed ... and the config value is that it doesn't NEED to be installed
						$PVContext.WriteLog("WSFC Components Installed - but not _REQUIRED_ via Config. Proviso will NOT uninstall WSFC components. Manually use [Uninstall-WindowsFeature Failover-Clustering] if needed.", "Important");
					}
				}
			}
		}
		
		Facet "PoshV5SelfRemotingEnabled" -NoKey -Expect $true {
			Test {
				return Get-SelfRemotingToNativePoshEnabled;
			}
			Configure {
				# If we 'branched' to Configure, it's because this pre-requisite is NOT met, so no need for checks, just ENABLE:
				Enable-SelfRemotingToNativePosh;
			}
		}
	}
}