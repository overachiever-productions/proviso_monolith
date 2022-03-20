Set-StrictMode -Version 1.0;
 
Surface -Name "LocalAdministrators" -Target "Host" {
	
	Setup {
		$admins = Get-LocalGroupMember -Group Administrators | Select-Object -Property "Name";
		$PVContext.SetSurfaceState("CurrentAdmins", $admins);
	}
	
	Assertions {
		Assert-UserIsAdministrator;
		
		Assert-HostIsWindows;
	}
	
	Aspect -Scope "LocalAdministrators" {
		#Facet "AccountExists" -ExpectCurrentKeyValue {
		Facet "AccountExists" -NoKey -ExpectIteratorValue {
			Test {
				$expectedAccount = $PVContext.CurrentConfigKeyValue;
		
				$exists = ConvertTo-WindowsSecurityIdentifier -Name $expectedAccount;
				if ($exists) {
					return $expectedAccount;
				}
				
				return "";
			}
			Configure {
				$expectedAccount = $PVContext.CurrentConfigKeyValue;
				throw "Unable to CREATE AD or LOCAL user [$expectedAccount]. Proviso can't/won't know the password or other critical detaiils. Make sure this user EXISTS before continuing.";
			}
		}
		
		#Facet "IsLocalAdmin" -Expect $true { 
		Facet "IsLocalAdmin" -Expect $true -NoKey {
			Test {
				$expectedAccount = $PVContext.CurrentConfigKeyValue;
				
				$currentAdmins = $PVContext.GetSurfaceState("CurrentAdmins");
				if ($currentAdmins.Name -contains $expectedAccount) {
					return $true;
				}
				
				return $false;
			}
			Configure {
				$expectedAccount = $PVContext.CurrentConfigKeyValue;
				
				Add-LocalGroupMember -Group Administrators -Member $expectedAccount;
				$PVContext.WriteLog("Added [$expectedAccount] to Local Administrators Group...", "Verbose");
				
				# reset/reload local admins: 
				$newAdmins = Get-LocalGroupMember -Group Administrators | Select-Object -Property "Name";
				$PVContext.SetSurfaceState("CurrentAdmins", $newAdmins);
			}
		}
	}
}