Set-StrictMode -Version 1.0;

# . ..\functions\DSL\Facet.ps1

Facet "ServerName" {
	# assert we're admins
	
	Assertions {
		Assert "Adminstrator" -Fatal {
			$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
			# todo... see if current user is in the admins role... 
			# if not, throw... 
		}
		Assert "Domain Admin Creds" -Fatal {
			# TODO: implement this correctly... i.e., this is just a VERY rough stub.
			if ($Config.GetValue("Host.TargetDomain") -ne $null) {
				# make sure we've got $Config.Secrets.DomainAdminCreds or whatever... 
				# othrwise, throw... 
			}
		}
	}
	
	Definitions {
		Definition "Target Server" {
			Expect {
				$Config.GetValue("Host.TargetServer");
			}
			Test {
				[System.Net.Dns]::GetHostName();
			}
			Configure {
				# check domain too... 
				# and rename host or rename + domain. 
			}
		}
		
		Definition "Target Domain" {
			Expect {
				$Config.GetValue("Host.TargetDomain");
			}
			Test{
				(Get-CimInstance Win32_ComputerSystem).Domain;
			}
			Configure {
				# if machine name is fine, then just join domain. 
				# otherwise, check to see if we've got a restart pending or whatever. 
				# which means we need a FacetContext (ProvisioningContext/ProvisoContext)
				# 		something that keeps tabs on some key values/details like .RestartRequired / etc. 
				
				# at any rate: Target Server SHOULD, in most cases, handle domain-join + host rename. 
				# meaning that this should just be domain-join if/when the host is already good. 
				
				# if we end up needing to reboot... make sure to signal that up:
				$ProvisoContext.RequiresReboot = $true;
			}
		}
	}
}