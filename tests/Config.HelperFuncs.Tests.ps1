Set-StrictMode -Version 1.0;

BeforeAll {
	$global:PVConfig = $null; # make sure this gets reset before all tests in here, otherwise it's global and 'leaks' previous state/configs... 
	
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "");
	
	. "$root\proviso.meta.ps1";
	Import-ProvisoTypes -ScriptRoot $root;
	
	. "$root\internal\dsl\ProvisoConfig.ps1";
	. "$root\internal\dsl\ProvisoConfig-Defaults.ps1";
	
	$script:be8c742fDefaultConfigData = $script:ProvisoConfigDefaults;
	
	filter Fake-NoAGsConfigData {
		$output = @{
		}
		
		return $output;
	}
	
	filter Fake-ImplicitAGInstanceConfigData {
		$output = @{
			AvailabilityGroups = @{
				Enabled		      = $true
				EvictionBehavior  = "WARN"
				
				MirroringEndpoint = @{
					Enabled						    = $true
					PortNumber					    = 5022
					Name						    = "HaDr"
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-ExplicitAGInstanceConfigData {
		$output = @{
			AvailabilityGroups = @{
				X99 = @{
					Enabled		      = $true
					EvictionBehavior  = "WARN"
					
					MirroringEndpoint = @{
						Enabled						    = $false
						PortNumber					    = 5022
						Name						    = "HaDr"
						AllowedOwnersConnectingAccounts = @("{~EMPTY~}") # e.g., xyZAdmin, sa, etc... 
					}
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-MultipleSqlInstanceAGConfigData {
		$output = @{
			AvailabilityGroups = @{
				X99 = @{
					Enabled		      = $true
					EvictionBehavior  = "WARN"
					
					MirroringEndpoint = @{
						Enabled						    = $true
						PortNumber					    = 5022
						Name						    = "HaDr"
						AllowedOwnersConnectingAccounts = @("{~EMPTY~}") # e.g., xyZAdmin, sa, etc... 
					}
				}
				MSSQLSERVER = @{
					Enabled		      = $true
					EvictionBehavior  = "WARN"
					
					MirroringEndpoint = @{
						Enabled						    = $true
						PortNumber					    = 5023
						Name						    = "HaDr"
					}
				}
			}
		}
		
		return $output;
	}
}

Describe "Get-SqlInstanceNames Tests" {
	Context "Functionality Tests" {
		It "Returns Nothing when AGs are Not Configured" {
			Set-ConfigTarget -ConfigData (Fake-NoAGsConfigData) -Strict:$false;
			
			($PVConfig.GetSqlInstanceNames("AvailabilityGroups")).Count | Should -Be 0;
		}
		
		It "Returns MSSQLSERVER for Implicit Keys" {
			Set-ConfigTarget -ConfigData (Fake-ImplicitAGInstanceConfigData) -Strict:$false;
			
			$results = @($PVConfig.GetSqlInstanceNames("AvailabilityGroups"));
			$results.Count | Should -Be 1;
			$results[0] | Should -Be "MSSQLSERVER";
		}
		
		It "Returns Explicit Instance Name When Configured" {
			Set-ConfigTarget -ConfigData (Fake-ExplicitAGInstanceConfigData) -Strict:$false;
			
			$results = @($PVConfig.GetSqlInstanceNames("AvailabilityGroups"));
			$results.Count | Should -Be 1;
			$results[0] | Should -Be "X99";
		}
		
		It "Returns Multiple Instances when Configured" {
			Set-ConfigTarget -ConfigData (Fake-MultipleSqlInstanceAGConfigData) -Strict:$false;
			
			$results = @($PVConfig.GetSqlInstanceNames("AvailabilityGroups"));
			$results.Count | Should -Be 2;
			# NOTE... I've had this order FLIP in previous tests ... may need to do a 'contains' test here instead of by ordinal... 
			$results[0] | Should -Be "X99";
			$results[1] | Should -Be "MSSQLSERVER";
		}
		
	}
}
