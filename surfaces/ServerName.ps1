Set-StrictMode -Version 1.0;

<#
	Notes on OUTCOMEs and CONFIGURATION
	Sadly, optional machine-rename + optional domain-join lead to an ugly number of permutations in terms of outcomes that can happen when configuring machine/domian names: 
		A. No change to Server-Name or Domain-Name. 
		B. Change to Server-Name (only). 
		C. Change to Domain-Name (only) - i.e., machine-name is correct, but we need to join the domain. 
		D. Change both Server-Name and Domain-Name (i.e., rename box + join domain). 

	In this surface, the "Target Server" Description will handle outcome B and D. Outcome D will be handled by "Target Domain". (And outcome A obviously doesn't need to be handled).

#>


Surface "ServerName" {
	
	Assertions {
		
		Assert-UserIsAdministrator -FailureMessage "Server Rename operations require User to be Administrator.";
		
		Assert-HostIsWindows -FailureMessage "Surface [ServerName] is currently only configured to execute against Windows Server instances";
		
		Assert-HasDomainCreds -ForDomainJoin;
		
		Assert "TargetServerNameIsNetBiosCompliant" -FailureMessage "TargetServer value specified in config exceeds 15 chars in legth." {
			$targetMachineName = $PVConfig.GetValue("Host.TargetServer");
			
			return ($targetMachineName.Length -le 15);
		}
		
		Assert -DoesNotExist "Target Domain Machine" {
			
			$targetDomain = $PVConfig.GetValue("Host.TargetDomain");
			
			$currentMachineName = [System.Net.Dns]::GetHostName();
			$targetMachineName = $PVConfig.GetValue("Host.TargetServer");
			
			if ($currentMachineName -ne $targetMachineName) {
				if ($targetDomain -ne "") {
					# https://overachieverllc.atlassian.net/browse/PRO-83
					# Write-Host "TODO: CHECK against [$targetDomain] to see if [$targetMachineName] already exists...";
				}
			}

			return $false; # inverted... 
		}
	}
	
	Scope {
		Facet -For "Target Server" -ExpectKeyValue "Host.TargetServer" -RequiresReboot {
			Test {
				return [System.Net.Dns]::GetHostName();
			}
			Configure {
				$targetMachineName = $PVConfig.GetValue("Host.TargetServer");
				
				# see notes on Outcomes/configuration in comments at the top of this surface:
				# since we're in here, we already KNOW that the current HostName doesn't match the Desired (Target) host-name. 
				#  so, we've already achieved 'at least' outcome B. Question is, did we achieve outcome D (server-rename AND domain-join)?
				$currentDomain = $PVContext.GetSurfaceState("CurrentDomain");
				$targetDomainName = $PVConfig.GetValue("Host.TargetDomain");
				
				if ($targetDomainName -ne $currentDomain) {
					# OUTCOME D
					$PVContext.AddSurfaceState("JoiningDomainAsPartOfRename", $true);
					
					$PVContext.WriteLog("Renaming Host [$([System.Net.Dns]::GetHostName())] to [$targetMachineName] and joining the [$targetDomainName] Domain.", "Important");
					try {
						Add-Computer -DomainName $targetDomainName -NewName $targetMachineName -Credential $credentials -Restart:$false | Out-Null;
					}
					catch {
						throw "Fatal Exception during Renaming Host [$([System.Net.Dns]::GetHostName())] during Domain-Join Operation: $_ `r`t$($_.ScriptStackTrace) ";
					}
				}
				else {
					# OUTCOME B (we just need to change the host name):
					$PVContext.WriteLog("Renaming Host [$([System.Net.Dns]::GetHostName())] to [$targetMachineName].", "Important");
					
					try {
						Rename-Computer -NewName $targetMachineName -Force -Restart:$false | Out-Null;
					}
					catch {
						throw "Fatal Exception while Renaming Host [$([System.Net.Dns]::GetHostName())] to [$targetDomainName]: $_ `r`t$($_.ScriptStackTrace) ";
					}
				}
				
				# if we got here, there were no exceptions:
				$PVContext.SetRebootRequired("Host-Name Change Requires Reboot.");
			}
		}
		
		Facet -For "Target Domain" -ExpectKeyValue "Host.TargetDomain" -RequiresReboot {
			Test {
				$domain = (Get-CimInstance Win32_ComputerSystem).Domain;
				if ($domain -eq "WORKGROUP") {
					$domain = "";
				}
				
				$PVContext.AddSurfaceState("CurrentDomain", $domain);
				
				return $domain; 
			}
			Configure {
				
				# see notes on Outcomes/configuration in comments at the top of this surface:
				#   We're either dealing with Outcome C or D. But D will be handled by "Target Server"
				$currentHostName = [System.Net.Dns]::GetHostName();
				$targetMachineName = $PVConfig.GetValue("Host.TargetServer");
				
				if ($targetMachineName -ne $currentHostName){
					# Outcome D - should be getting handled in "Target Machine": 
					$handled = $PVContext.GetSurfaceState("JoiningDomainAsPartOfRename");
					
					if ($handled){
						throw "Exception processing Host-Name Change and/or Domain-Name Join... ";
					}
				}
				else {
					# Outcome C - domain-name change only - handled here: 
					
					$targetDomainName = $PVConfig.GetValue("Host.TargetDomain");
					
					$PVContext.WriteLog("Adding Host [$currentHostName] to Domain [$targetDomainName].", "Important");
					
					try {
						Add-Computer -DomainName $targetDomainName -Credential $credentials -Restart:$false | Out-Null;
					}
					catch {
						throw "Fatal Exception while During Domain-Join of Host [$([System.Net.Dns]::GetHostName())] to [$targetDomainName]: $_ `r`t$($_.ScriptStackTrace) ";
					}
				}
				
				$PVContext.SetRebootRequired("Host-Name Change Requires Reboot.");
			}
		}
	}
}