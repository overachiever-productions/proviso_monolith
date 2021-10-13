Set-StrictMode -Version 1.0;

Facet -For "Network-Definitions" {
	
	Assertions {
		
	}
	
	Rebase {
		
	}
	
	Definitions {
		
		Definition -Has "VM-Network" {
			Expect {
				
			}
			Test {
				Get-ExistingAdapters | Where-Object {$_.Name -eq $Config.GetValue("Host.NetworkDefinitions")}
			}
			Configure {
				
			}
		}
		
		Definition -For "IP-Address" {
			Expect {
				$Config.GetValue("Host.NetworkDefinitions.VMNetwork.IpAddress");
			}
			Test {
				
			}
			Configure {
				
			}
		}
	}
}