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
		
		Definition "ICMP" -Key "Host.FirewallRules.EnableICMP" {
			Test {
				$rule = Get-NetFirewallRule -DisplayName "FPS-ICMP4-ERQ-In" -ErrorAction SilentlyContinue;
				if (($null -eq $rule) -or (-not($rule.Enabled))) {
					return $false;
				}
				
				return $true;
			}
			Configure {
				Set-NetFirewallRule -Name "FPS-ICMP4-ERQ-In" -Enabled true | Out-Null;
			}
		}
		
	}
}