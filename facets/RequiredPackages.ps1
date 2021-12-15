#Set-StrictMode -Version 1.0;
#
#Facet "RequiredPackages" -For -Key "Host.RequiredPackages" {
#	
#	Assertions {
#		Assert -Is "Adminstrator" -FailureMessage "Current User is not a Member of the Administrators Group" {
#			$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
#			$admins = Get-LocalGroupMember -Group Administrators | Select-Object -Property "Name";
#			
#			if ($admins.Name -notcontains $currentUser) {
#				return $false;
#			}
#		}
#		
#		Assert -Is "WindowsServer" {
#			$os = (Get-ChildItem -Path Env:\POWERSHELL_DISTRIBUTION_CHANNEL).Value;
#			if ($os -notlike "*Windows Server*") {
#				return $true;
#			}
#		}
#	}
#	
#	Definitions {
#		Definition -Key "Host.RequiredPackages.WsfcComponents" {
#			Test {
#				$installed = (Get-WindowsFeature -Name Failover-Clustering).InstallState;
#				
#				if ($installed -eq "Installed") {
#					return $true;
#				}
#				
#				return $false;
#			}
#			
#			Configure {
#				# Hmm. This one's a bit odd. we only want to install it if it's REQUIRED. 
#				# And we never want to UNINSTALL it. 
#				if ($Config.GetValue("Host.RequiredPackages.WsfcComponents")) {
#					$processingError = $null;
#					$outcome = Install-WindowsFeature Failover-Clustering -IncludeManagementTools -ErrorVariable processingError;
#					
#				}
#			}
#		}
#		
#		Definition -Key "Host.RequiredPackages.NetFxForPre2016InstancesRequired" {
#			Test {
#				throw "Not Implemented";
#			}
#			
#			Configure {
#				throw "Not Implemented";
#			}
#		}
#		
#		Definition -Key "Host.RequiredPackages.AdManagementFeaturesforPowershell6PlusRequired" {
#			Test {
#				$state = (Get-WindowsFeature RSAT-AD-Powershell).InstallState;
#				if ($state -eq "installed") {
#					return $true;
#				}
#				return $false;
#			}
#			
#			Configure {
#				# again, only want to install this if it's REQUIRED.
#				Install-WindowsFeature RSAT-AD-Powershell;
#			}
#		}
#	}
#}

# . ..\functions\DSL\Facet.ps1
#
#Facet "RequiredPackages" {
#	
#	Assertions {
#		Assert "Executing as Administrator." {
#			$x = "this is a script block";
#		}
#		Assert "Windows Server Edition" {
#			$y = "so is this";
#		}
#	}
#	
#	Definitions {
#		Definition "Wsfc Installed" {
#			$y = "pretend this is a script";
#		}
#		
#		Definition "NetFx For Pre-2016 Instances" {
#			$y = "this too....";
#		}
#	}
#}