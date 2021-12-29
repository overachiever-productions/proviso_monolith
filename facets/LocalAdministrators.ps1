Set-StrictMode -Version 1.0;

Facet "LocalAdmins" -For -Key "Host.LocalAdministrators" {
	
	Setup {
		$admins = Get-LocalGroupMember -Group Administrators | Select-Object -Property "Name";
		$PVContext.AddFacetState("CurrentAdmins", $admins);
	}
	
	Assertions {
		Assert-UserIsAdministrator;
		
		Assert-HostIsWindows;
	}
	
	Value-Definitions -ValueKey "Host.LocalAdministrators" {
		
		Definition "AccountExists" -ExpectCurrentKeyValue {
			Test {
				$expectedAccount = $PVContext.CurrentKeyValue;
				
				$exists = ConvertTo-WindowsSecurityIdentifier -Name $expectedAccount;
				if ($exists) {
					return $expectedAccount;
				}
				
				return "";
			}
			Configure {
				$expectedAccount = $PVContext.CurrentKeyValue;
				throw "Unable to CREATE AD or LOCAL user [$expectedAccount]. Proviso can't/won't know the password or other critical detaiils. Make sure this user EXISTS before continuing.";
			}
		}
		
		Definition "IsLocalAdmin" -Expect $true { 
			Test {
				$expectedAccount = $PVContext.CurrentKeyValue;
				$currentAdmins = $PVContext.GetFacetState("CurrentAdmins");
				
				if ($currentAdmins.Name -contains $expectedAccount) {
					return $true;
				}
				
				return $false;
			}
			Configure {
				$expectedAccount = $PVContext.CurrentKeyValue;
				
				Add-LocalGroupMember -Group Administrators -Member $expectedAccount;
				$PVContext.WriteLog("Added [$expectedAccount] to Local Administrators Group...", "Verbose");
				
				# reset/reload local admins: 
				$newAdmins = Get-LocalGroupMember -Group Administrators | Select-Object -Property "Name";
				$PVContext.OverwriteFacetState("CurrentAdmins", $newAdmins);
			}
		}
	}
}