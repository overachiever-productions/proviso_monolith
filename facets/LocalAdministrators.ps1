Set-StrictMode -Version 1.0;

Facet "LocalAdministrators" -For -Key "Host.LocalAdministrators" {
	
	Assertions {
		Assert -Is "Adminstrator" -FailureMessage "Current User is not a Member of the Administrators Group" {
			$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
			$admins = Get-LocalGroupMember -Group Administrators | Select-Object -Property "Name";
			
			if ($admins.Name -notcontains $currentUser) {
				return $false;
			}
		}
		
		Assert -Is "WindowsServer" {
			$os = (Get-ChildItem -Path Env:\POWERSHELL_DISTRIBUTION_CHANNEL).Value;
			if ($os -notlike "*Windows Server*") {
				return $true;
			}
		}
	}
	
	Value-Definitions -ValueKey "Host.LocalAdministrators" {
		
		Definition "AccountExists" -ExpectCurrentKeyValue {
			# NOTE: this 'test' is currently using -ExpectCurrentKeyValue ... that'd be used in a scenario like, say, where we were looking for a specific IP
			#   or some other 'scalar' (non-true/false) value ... instead of just wanting true/false/etc. 
			Test {
				
				$actualStateOfCurrentValue = "Some String here";
				if (($PVContext.CurrentKeyValue) -eq "OA\mike-c") {
					$actualStateOfCurrentValue = $PVContext.CurrentKeyValue;
				}
				
				#return (($PVContext.Expected) -eq $actualStateOfCurrentValue);
				return $actualStateOfCurrentValue;
			}
			Configure {
				Write-Host "making xxx exist... ";
			}
		}
		
		Definition "IsMemberOfLocalAdmins" { 
			Expect {
				# NOTE: this is currently just a weak-ass simulation:  
				# NOTE: even more importantly... I THINK i really just need to hard-code this crap to be $true. 
				# 		as in, the BIZ LOGIC here is that for each 'entry' in Host.LocalAdministrators... we're EXPECTING them to be members of LocalAdmins. 
				# 			i.e., that's the EXPECTATION... evaluation (and then possible configuration) is another story... 
				#   which means... that I think I can change this Definition to => Definition "IsMemberOfLocalAdmins" -Expect $true { etc... }
				$currentAccountName = $PVContext.CurrentKeyValue;
				
				if ($currentAccountName -eq "OA\mike-c") {
					return $true; # i.e., pretend that the account currently being evaluated IS a member of local admins... 
				}
				
				return $false;
			}
			Test {
				# whatever code is needed to see if <currentKey> is a member of LocalAdmins - i..e, return $true or $false. 
				#Write-Host "Inside of LocalAdmins.IsAdmin... looking for info on $($PVContext.CurrentKeyValue) ";
				
				return $false;
			}
			Configure {
				# code to push <currentKey> into/as a member of LocalAdmins. 
				Write-Host "Adding $($PVContext.CurrentKeyValue) to local admins...";
			}
		}
	}
}