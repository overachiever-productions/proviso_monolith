Set-StrictMode -Version 1.0;

Surface "FirewallRules" -Target "Host" {
	
	Assertions {
		Assert-UserIsAdministrator;
		
		Assert-HostIsWindows;
		
		Assert -Is "WindowsFirewallEnabled" -NonFatal {
			$states = Get-NetFirewallProfile | Select-Object -Property Enabled;
			if (-not ($states)) {
				$PVContext.SetSurfaceState("WindowsFirewall.Enabled", $false);
				return $false;
			}
			
			$PVContext.SetSurfaceState("WindowsFirewall.Enabled", $true);
			return $true;
		}
	}
	
#	Rebase {
#		# this particular surface MIGHT make sense as a case where a Rebase is needed/required before processing stuff. 
#		# and ... the rebase would be to REMOVE all existing Firewall Rules matching the names of the rules defined below? 
#		
#		# either way, what I need to do here is, sigh, 2x things: 
#		#  a. there's NOTHING stopping me from creating a New-NetFirewallRule that's the exact same as the one before - i.e., I can run these 3x lines of 
#		#  		code without ANY problems or errors: 
#		
#		
#		# 		what I'll end up with, though, is 3x rules with the same 'name' (different GUIDs)... which is a friggin mess. 
#		# b. arguably, if the config says: $false for a given rule (e.g., mirroring, or ICMP), then... I want to nuke the rule instead of recreating it as $true (open)
#	}
	
	Aspect -Scope "FirewallRules" {
		#Facet "SQL Server" -ExpectKeyValue "Host.FirewallRules.EnableFirewallForSqlServer" {
		Facet "SQL Server" -Key "EnableFirewallForSqlServer" -ExpectKeyValue {
			Test {
				if (-not ($PVContext.GetSurfaceState("WindowsFirewall.Enabled"))) {
					return $false;
				}
				
				$rule = Get-NetFirewallRule -DisplayName "SQL Server" -ErrorAction SilentlyContinue;
				if (($null -eq $rule) -or (-not ($rule.Enabled))) {
					return $false;
				}
				
				return $true;
			}
			Configure {
				if (-not ($PVContext.GetSurfaceState("WindowsFirewall.Enabled"))) {
					$PVContext.WriteLog("Windows Firewall is NOT enabled.", "Critical");
				}
				else {
					#$enable = $PVConfig.GetValue("Host.FirewallRules.EnableFirewallForSqlServer");
					$enable = $PVContext.CurrentConfigKeyValue;
					
					$exists = Get-NetFirewallRule -DisplayName "SQL Server" -ErrorAction SilentlyContinue;
					if ($enable){
						if ($exists) {
							Set-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 1433 | Out-Null;
						}
						else {
							New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 1433 | Out-Null;
						}
					}
					else {
						# disable / remove:
						Remove-NetFirewallRule -DisplayName "SQL Server";
					}
				}
			}
		}
		
		#Facet "SQL Server - DAC" -ExpectKeyValue "Host.FirewallRules.EnableFirewallForSqlServerDAC" {
		Facet "SQL Server - DAC" -Key "EnableFirewallForSqlServerDAC" -ExpectKeyValue {
			Test {
				if (-not ($PVContext.GetSurfaceState("WindowsFirewall.Enabled"))) {
					return $false;
				}
				
				$rule = Get-NetFirewallRule -DisplayName "SQL Server - DAC" -ErrorAction SilentlyContinue;
				if (($null -eq $rule) -or (-not ($rule.Enabled))) {
					return $false;
				}
				
				return $true;
			}
			Configure {
				if (-not ($PVContext.GetSurfaceState("WindowsFirewall.Enabled"))) {
					$PVContext.WriteLog("Windows Firewall is NOT enabled.", "Critical");
				}
				else {
					#$enable = $PVConfig.GetValue("Host.FirewallRules.EnableFirewallForSqlServerDAC");
					$enable = $PVContext.CurrentConfigKeyValue;
					
					$exists = Get-NetFirewallRule -DisplayName "SQL Server - DAC" -ErrorAction SilentlyContinue;
					
					if ($enable) {
						if ($exists) {
							Set-NetFirewallRule -DisplayName "SQL Server - DAC" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 1434 | Out-Null;
						}
						else {
							New-NetFirewallRule -DisplayName "SQL Server - DAC" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 1434 | Out-Null;
						}
					}
					else {
						# disable / remove:
						Remove-NetFirewallRule -DisplayName "SQL Server - DAC";
					}
				}
			}
		}
		
		#Facet "SQL Server - Mirroring" -ExpectKeyValue "Host.FirewallRules.EnableFirewallForSqlServerMirroring" {
		Facet "SQL Server - Mirroring" -Key "EnableFirewallForSqlServerMirroring" -ExpectKeyValue {
			Test {
				if (-not ($PVContext.GetSurfaceState("WindowsFirewall.Enabled"))) {
					return $false;
				}
				
				$rule = Get-NetFirewallRule -DisplayName "SQL Server - Mirroring" -ErrorAction SilentlyContinue;
				if (($null -eq $rule) -or (-not ($rule.Enabled))) {
					return $false;
				}
				
				return $true;
			}
			Configure {
				if (-not ($PVContext.GetSurfaceState("WindowsFirewall.Enabled"))) {
					$PVContext.WriteLog("Windows Firewall is NOT enabled.", "Critical");
				}
				else {
					#$enable = $PVConfig.GetValue("Host.FirewallRules.EnableFirewallForSqlServerMirroring");
					$enable = $PVContext.CurrentConfigKeyValue;
					
					$exists = Get-NetFirewallRule -DisplayName "SQL Server - Mirroring" -ErrorAction SilentlyContinue;
					
					if ($enable) {
						if ($exists) {
							Set-NetFirewallRule -DisplayName "SQL Server - Mirroring" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5022 | Out-Null;
						}
						else {
							New-NetFirewallRule -DisplayName "SQL Server - Mirroring" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5022 | Out-Null;
						}
					}
					else {
						# disable / remove:
						Remove-NetFirewallRule -DisplayName "SQL Server - Mirroring";
					}
				}
			}
		}
		
		#Facet "ICMP" -ExpectKeyValue "Host.FirewallRules.EnableICMP" {
		Facet "ICMP" -Key "EnableICMP" -ExpectKeyValue {
			Test {
				# TODO: verify that this rule (name) works on instances of WIndows Server OTHER than 2019... 
				# NOTE: ACTUAL name (vs display name) for this rule is: "FPS-ICMP4-ERQ-In"
				$rule = Get-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -ErrorAction SilentlyContinue;
				if (($null -eq $rule) -or (-not ($rule.Enabled))) {
					return $false;
				}
				
				return $true;
			}
			Configure {
				if (-not ($PVContext.GetSurfaceState("WindowsFirewall.Enabled"))) {
					$PVContext.WriteLog("Windows Firewall is NOT enabled.", "Critical");
				}
				else {
					#$enable = $PVConfig.GetValue("Host.FirewallRules.EnableICMP");
					$enable = $PVContext.CurrentConfigKeyValue;
					
					$exists = Get-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -ErrorAction SilentlyContinue;
					
					if ($enable) {
						if ($exists) {
							Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Enabled True;
						}
						else {
							throw "Windows NetFirewallRule 'File and Printer Sharing (Echo Request - ICMPv4-In) not found and cannot be SET.";
						}
					}
					else {
						# disable / remove:
						Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Action Block;
					}
				}
			}
		}
	}
}