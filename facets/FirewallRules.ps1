Set-StrictMode -Version 1.0;

Facet "FirewallRules" -For -Key "Host.FirewallRules" {
	
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
		
		#TODO: Implement (and... MAYBE if the firewall is off, then ... hmmm. (was going to say... change the tests/outcomes... but that's a good idea and a TERRIBLE idea).)
#		Assert -Is "Windows Firewall Enabled" {
#			$states = Get-NetFirewallProfile | Select-Object -Property Enabled;
#			if (-not ($states)){
#				return $false;
#			}
#		}
	}
	
	Rebase {
		# this particular facet MIGHT make sense as a case where a Rebase is needed/required before processing stuff. 
		# and ... the rebase would be to REMOVE all existing Firewall Rules matching the names of the rules defined below? 
		
		# either way, what I need to do here is, sigh, 2x things: 
		#  a. there's NOTHING stopping me from creating a New-NetFirewallRule that's the exact same as the one before - i.e., I can run these 3x lines of 
		#  		code without ANY problems or errors: 
		
		
		# 		what I'll end up with, though, is 3x rules with the same 'name' (different GUIDs)... which is a friggin mess. 
		# b. arguably, if the config says: $false for a given rule (e.g., mirroring, or ICMP), then... I want to nuke the rule instead of recreating it as $true (open)
	}
	
	Definitions {
		
		Definition "SQL Server" -Key "Host.FirewallRules.EnableFirewallForSqlServer" {
			Test {
				$rule = Get-NetFirewallRule -DisplayName "SQL Server" -ErrorAction SilentlyContinue;
				if (($null -eq $rule) -or (-not ($rule.Enabled))) {
					return $false;
				}
				
				return $true;
			}
			Configure {
				New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 1433 | Out-Null;
			}
		}
		
		Definition "SQL Server - DAC" -Key "Host.FirewallRules.EnableFirewallForSqlServerDAC" {
			Test {
				$rule = Get-NetFirewallRule -DisplayName "SQL Server - DAC" -ErrorAction SilentlyContinue;
				if (($null -eq $rule) -or (-not ($rule.Enabled))) {
					return $false;
				}
				
				return $true;
			}
			Configure {
				New-NetFirewallRule -DisplayName "SQL Server - DAC" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 1434 | Out-Null;
			}
		}
		
		Definition "SQL Server - Mirroring" -Key "Host.FirewallRules.EnableFirewallForSqlServerMirroring" {
			Test {
				$rule = Get-NetFirewallRule -DisplayName "SQL Server - Mirroring" -ErrorAction SilentlyContinue;
				if (($null -eq $rule) -or (-not ($rule.Enabled))) {
					return $false;
				}
				
				return $true;
			}
			Configure {
				New-NetFirewallRule -DisplayName "SQL Server - Mirroring" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5022 | Out-Null;
			}
		}
		
		# So... yeah... this thing just does NOT exist... on all Windows Server 2019 instances... 
		#  need to do a bit more work on figuring out how to deal with this. 
#		Definition "ICMP" -Key "Host.FirewallRules.EnableICMP" {
#			Test {
#				$rule = Get-NetFirewallRule -DisplayName "FPS-ICMP4-ERQ-In" -ErrorAction SilentlyContinue;
#				if (($null -eq $rule) -or (-not($rule.Enabled))) {
#					return $false;
#				}
#				
#				return $true;
#			}
#			Configure {
#				Set-NetFirewallRule -Name "FPS-ICMP4-ERQ-In" -Enabled true | Out-Null;
#			}
#		}
		
	}
}