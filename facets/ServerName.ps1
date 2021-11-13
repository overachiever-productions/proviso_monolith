Set-StrictMode -Version 1.0;

Facet "ServerName" {
	
	Assertions {
		Assert "Fake Test" -NotFatal -Ignored {
			throw "Test Exception."; # simple test of non-fatal assertions... 
		}
		
		Assert -Is "Adminstrator" -FailureMessage "Current User is not a Member of the Administrators Group" {
			$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
			$admins = Get-LocalGroupMember -Group Administrators | Select-Object -Property "Name";
			
			if ($admins.Name -contains $currentUser) {
				return $true;
			}
			
			return $false;
		}
		
		Assert -Has "Domain Admin Creds" {
#			if ($Config.GetValue("Host.TargetDomain") -ne $null) {
#				
#				# make sure we've got $Config.Secrets.DomainAdminCreds or whatever... 
#				# othrwise, throw or return $false... 
#				return $false;
#			}
			
			return $true;
		}
		
		Assert -DoesNotExist "Target Domain Machine" {
			# if Host.TargetDomain & Host.TargetServer <> current values... 
			#   since we should, now, have domain creds... 
			#   use those to ensure that the <targteMachine>.<targetDomain> doesn't already exist... 
			#    i.e., sometimes when provisioning a new server - it's a REPAVE of an existing box - 
			# 			and if said 'box' already has been registered in AD (but the VM has been destroyed) we'll run into an error.
			
			# ARGUABLY: 
			#   an assert COULD detect the above an then TRY to drop the offending object from AD (i.e., do some automated cleanup)
			#   but there are TWO big/ugly things about that that I don't like:
			# 	1. Automating the REMOVAL of a machine from AD seems sketchy/dumb - i.e., I'd much rather get an alert: "Doh. Can rename xyz1234 to sql27.mydomain as sql27.mydomain already exists."
			#   2. Asserts are ... assertions, not places to 'do work'
			# 		along those lines, it'd be way better to have a Facet for 'AD cleanup' if/as needed as a PREDECESSOR to this facet (in a workflow/runbook)
			return $false; # inverted... 
		}
	}
	
	Rebase {
		Write-Host "<DO REBASE STUFF HERE>";
		$PVContext.SetRebootRequired("Rebase Requires Reboot for FULL reset.");
	}
	
	Definitions {
		Definition -For "Target Server" {
			Expect {
				$Config.GetValue("Host.TargetServer");
			}
			Test {
				$currentHost = [System.Net.Dns]::GetHostName();
				$PVContext.AddFacetState("CurrentHostName", $currentHost);
				return $currentHost;
			}
			Configure {
				
				# NOTE: this definition is for target server... but if the domain name needs to be changed too, we'll want to tackle that here. 
				$targetDomainName = $Config.GetValue("Host.TargetDomain");
				$currentDomainName = $PVContext.GetFacetState("CurrentDomain");
				
				#Write-Host "Configuration Example: TargetDomain: $targetDomainName => Current DomainName: $currentDomainName ";
				
				# assuming domain-join and rename went fine: 
				$PVContext.AddFacetState("JoinedToDomain", $true);  # which we can check down below... 
			}
		}
		
		Definition -For "Target Domain" {
			Expect {
				$Config.GetValue("Host.TargetDomain");
			}
			Test {
				$domain = (Get-CimInstance Win32_ComputerSystem).Domain;
				if ($domain -eq "WORKGROUP") {
					$domain = "";
				}
				
				$PVContext.AddFacetState("CurrentDomain", $domain);
				return $domain; 
			}
			Configure {
				
#				#region example-ish
#				if ((Context.GetTemporaryFacetValue("CurrentHostName")) -ne ($Config.GetValue("Host.TargetServer"))) {
#					#at this point, we know that ... domain-join isn't THE only thing we need. 
#					# we need both DOMAIN-JOIN _AND_ a name-change. 
#				}
#				#endregion				
				
				#assuming it's needed..: 
				$Context.SetRebootRequired("Computer Name Change from [old-name] to [new-name].");
			}
		}
	}
}