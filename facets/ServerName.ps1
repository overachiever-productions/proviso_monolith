Set-StrictMode -Version 1.0;

# . ..\functions\DSL\Facet.ps1

Facet "ServerName" {
	# assert we're admins
	
	Assertions {
		Assert "Fake Test" -NotFatal {
			throw "Test Exception."; # test of non-fatal assertions... 
		}
		
		Assert "Adminstrator" {
			# TODO: this logic is actually busted (contains isn't working like I want it to... ).
			$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
#			$admins = Get-LocalGroupMember -Group Administrators;
#			
#			if (-not ($admins -contains $currentUser)){
#				throw "$currentUser is not a member of Administrators.";
#			}
		}
		Assert "Domain Admin Creds" {
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
				#region Example of more-accurate(possibly?) implementation: 
#				$currentHost = [System.Net.Dns]::GetHostName();
#				$Context.StoreTemporaryFacetValue("CurrentHostName", $currentHost);
#				return $currentHost;
				#endregion 
				
				[System.Net.Dns]::GetHostName();
			}
			Configure {
				
				# TODO: check the domain as well... if that needs to be changed TOO... then... 
				#  hmm... maybe we skip this and let the Domain-Name Change operation/code handle this? 
				#   in which case, i might be able to do this: 
				# if (domainName -ne ExpecteDomainName) {
				#	Context.SetTemporaryFacetValue("NameChangeRequired", $true);
				#}
				#  and.... then, down in the Configure for "Target Domain":
				#    a. check for Context.GetTemporaryFacetValue("NameChangeRequired")
				#    b. if $true, then tackle that as well. 
				
				# i.e., there are a number of ways I can manage 'between operation' state.
				
				Write-Host "This is a test. But, what I'd do would be: a. check the domain-name (matched or not) too... and b) then change name or name+domain-join.";
			}
		}
		
		Definition "Target Domain" {
			Expect {
				$Config.GetValue("Host.TargetDomain");
			}
			Test{
				$domain = (Get-CimInstance Win32_ComputerSystem).Domain;
				if ($domain -eq "WORKGROUP") {
					$domain = "";
				}
				# TODO: "" (when 'domain' -eq WORKGROUP) and "" from the $Config.Host.TargetDomain ... aren't matching. THEY SHOULD BE... 
				# 		that's the whole purpose of the if(is-string) & if(empty)... inside of Compare-ExpectedWithActual.ps1;
				return $domain;  # ruh roh... it MIGHT be the return?
			}
			Configure {
				
				#region example-ish
				if ((Context.GetTemporaryFacetValue("CurrentHostName")) -ne ($Config.GetValue("Host.TargetServer"))) {
					#at this point, we know that ... domain-join isn't THE only thing we need. 
					# we need both DOMAIN-JOIN _AND_ a name-change. 
				}
				#endregion				
				
				$Context.SetRebootRequired("Computer Name Change from [old-name] to [new-name].");
			}
		}
	}
}