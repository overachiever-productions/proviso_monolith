Set-StrictMode -Version 1.0;

<#
	Notes on OUTCOMEs and CONFIGURATION
	Sadly, optional machine-rename + optional domain-join lead to an ugly number of permutations in terms of outcomes that can happen when configuring machine/domian names: 
		A. No change to Server-Name or Domain-Name. 
		B. Change to Server-Name (only). 
		C. Change to Domain-Name (only) - i.e., machine-name is correct, but we need to join the domain. 
		D. Change both Server-Name and Domain-Name (i.e., rename box + join domain). 

	In this facet, the "Target Server" Description will handle outcome B and D. Outcome D will be handled by "Target Domain". (And outcome A obviously doesn't need to be handled).

#>


Facet "ServerName" {
	
	Assertions {
		
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
		
		Assert "TargetServerNameIsNetBiosCompliant" -FailureMessage "TargetServer value specified in config exceeds 15 chars in legth." {
			$targetMachineName = $PVConfig.GetValue("Host.TargetServer");
			
			return ($targetMachineName.Length -le 15);
		}
	}
	
	Definitions {
		Definition -For "Target Server" -Key "Host.TargetServer" {
			Test {
				
				return [System.Net.Dns]::GetHostName();
			}
			Configure {
				$targetMachineName = $PVConfig.GetValue("Host.TargetServer");
				
				# see notes on Outcomes/configuration in comments at the top of this facet:
				# since we're in here, we already KNOW that the current HostName doesn't match the Desired (Target) host-name. 
				#  so, we've already achieved 'at least' outcome B. Question is, did we achieve outcome D (server-rename AND domain-join)?
				$currentDomain = $PVContext.GetFacetState("CurrentDomain");
				$targetDomainName = $PVConfig.GetValue("Host.TargetDomain");
				
				if ($targetDomainName -ne $currentDomain) {
					# OUTCOME D
					$PVContext.AddFacetState("JoiningDomainAsPartOfRename", $true);
					
					$PVContext.WriteLog("Renaming Host [$([System.Net.Dns]::GetHostName())] to [$targetMachineName] and joining the [$targetDomainName] Domain.", "Important");
					#Add-Computer -DomainName $targetDomainName -NewName $targetMachineName -Credential $credentials -Restart:$false;
				}
				else {
					# OUTCOME B (we just need to change the host name):
					
					$PVContext.WriteLog("Renaming Host [$([System.Net.Dns]::GetHostName())] to [$targetMachineName].", "Important");
					#Rename-Computer -NewName $targetMachineName -Force -Restart:$false;
				}
						
				$PVContext.SetRebootRequired("Host-Name Change Requires Reboot.");
			}
		}
		
		Definition -For "Target Domain" -Key "Host.TargetDomain" {
			Test {
				$domain = (Get-CimInstance Win32_ComputerSystem).Domain;
				if ($domain -eq "WORKGROUP") {
					$domain = "";
				}
				
				$PVContext.AddFacetState("CurrentDomain", $domain);
				
				return $domain; 
			}
			Configure {
				
				# see notes on Outcomes/configuration in comments at the top of this facet:
				#   We're either dealing with Outcome C or D. But D will be handled by "Target Server"
				$currentHostName = [System.Net.Dns]::GetHostName();
				$targetMachineName = $PVConfig.GetValue("Host.TargetServer");
				
				if ($targetMachineName -ne $currentHostName){
					# Outcome D - should be getting handled in "Target Machine": 
					$handled = $PVContext.GetFacetState("JoiningDomainAsPartOfRename");
					
					if ($handled){
						throw "Exception processing Host-Name Change and/or Domain-Name Join... ";
					}
				}
				else {
					# Outcome C - domain-name change only - handled here: 
					
					$targetDomainName = $PVConfig.GetValue("Host.TargetDomain");
					
					$PVContext.WriteLog("Adding Host [$currentHostName] to Domain [$targetDomainName].", "Important");
					#Add-Computer -DomainName $targetDomainName -Credential $credentials -Restart:$false;
				}
				
				$PVContext.SetRebootRequired("Host-Name Change Requires Reboot.");
			}
		}
	}
}