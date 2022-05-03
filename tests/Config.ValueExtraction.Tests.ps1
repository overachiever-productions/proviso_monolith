Set-StrictMode -Version 1.0;

BeforeAll {
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "");
	
	. "$root\internal\dsl\ProvisoConfig.ps1";
	. "$root\internal\dsl\ProvisoConfig-Defaults.ps1";
	$script:be8c742fDefaultConfigData = $script:ProvisoConfigDefaults;
	
	function Fake-NetworkConfig {
		$configData = @{
			Host = @{
				TargetServer	   = "PRO-197"
				TargetDomain	   = ""
				
				NetworkDefinitions = @{
					VMNetwork = @{
						ProvisioningPriority = 1
						InterfaceAlias	     = "VM Network"
						
						AssumableIfNames	 = @(
							"Ethernet0"
							"Ethernet1"
						)
						
						IpAddress		     = "10.0.20.197/16"
						Gateway			     = "10.0.0.1"
						PrimaryDns		     = "10.0.0.210"
						SecondaryDns		 = "208.67.220.220"
					}
				}
			}
		};
		
		return $configData;
	}
	
	function Fake-CoreHostDetails {
		
		# excludes Disks and NICs config... 
		$configData = @{
			Host = @{
				TargetServer	   = "PRO-197"
				TargetDomain	   = ""
				
				LocalAdministrators = @(
					"OVERACHIEVER\dev-ops"
					"OVERACHIEVER\dbas"
				)
				
				WindowsPreferences = @{
					DvdDriveToZ				     = $true
					OptimizeExplorer			 = $true
					DisableServerManagerOnLaunch = $true
					SetPowerConfigHigh		     = $true
					DisableMonitorTimeout	     = $true
					EnableDiskPerfCounters	     = $true
				}
				
				RequiredPackages   = @{
					WsfcComponents								   = $true
					
					NetFxForPre2016InstancesRequired			   = $false
					AdManagementFeaturesforPowershell6PlusRequired = $false
				}
				
				LimitHostTls1dot2Only = $true
				
				FirewallRules	   = @{
					EnableFirewallForSqlServer		    = $true
					EnableFirewallForSqlServerDAC	    = $true
					EnableFirewallForSqlServerMirroring = $true
					
					EnableICMP						    = $true
				}
			}
		}
		
		return $configData;
	}
	
	function Fake-BasicExtendedEventsDetails {
		$configData = @{
			ExtendedEvents = @{
				MSSQLSERVER = @{
					DisableTelemetry = $true
					
					BlockedProcesses = @{
						SessionName	    = "blocked_processes"
						StartWithSystem = $true
					}
					
					CorrelatedSpills = @{
						SessionName = "correlated_spills"
						
					}
				}
			}
		}
		return $configData;
	}
	
#	function Fake-XXX {
#		$configData = @{
#		}
#		
#		return $configData;
#	}
#	
#	function Fake-XXX {
#		$configData = @{
#		}
#		
#		return $configData;
#	}
	
}

Describe "Static Key Extraction" {
	Context "Host Details" {
		It "Extracts Target HostName" {
			Set-ConfigTarget -ConfigData (Fake-CoreHostDetails);
			
			$PVConfig.GetValue("Host.TargetServer") | Should -Be "PRO-197";
		}
		
		It "Leaves TargetDomain Empty When Empty" {
			Set-ConfigTarget -ConfigData (Fake-CoreHostDetails);
			
			$PVConfig.GetValue("Host.TargetDomain") | Should -Be "";
		}
		
		It "Extracts TargetDomain When Specified" {
			Set-ConfigTarget -ConfigData (Fake-CoreHostDetails);
			$PVConfig.SetValue("Host.TargetDomain", "OVERACHIEVER.local");
			
			$PVConfig.GetValue("Host.TargetDomain") | Should -Be "OVERACHIEVER.local";
		}
	}
}

Describe "Sql Instance Key Extraction" {
	
}


Describe "Object-Key Extraction" {
	
}


Describe "Compound-Key Extraction" {
	Context "ExtendedEvents Tests" {
		It "Uses Default Xe Session Name (Parent Object) When NOT Provided" {
			Set-ConfigTarget -ConfigData (Fake-BasicExtendedEventsDetails);
			
			$PVConfig.GetValue("ExtendedEvents.MSSQLSERVER.PigglyWiggly.SessionName") | Should -Be "PigglyWiggly";
		}
		
		It "Uses Explicit Xe Session Name when Provided" {
			Set-ConfigTarget -ConfigData (Fake-BasicExtendedEventsDetails);
			
			$PVConfig.GetValue("ExtendedEvents.MSSQLSERVER.BlockedProcesses.SessionName") | Should -Be "blocked_processes";
		}
		
		It "Uses Session-Name as basis for Convention to supply definition file" {
			Set-ConfigTarget -ConfigData (Fake-BasicExtendedEventsDetails);
			
			$PVConfig.GetValue("ExtendedEvents.MSSQLSERVER.BlockedProcesses.DefinitionFile") | Should -Be "blocked_processes.sql";
		}
	}	
}

#	
#	Context "Expected Network Interfaces" {
#		It "Returns Empty when there are no Expected Interfaces" {
#			
#		}
#	}
#	
#	Context "Expected Disks" {
#		It "Returns Empty when there are no Expected Disks" {
#			
#		}
#	}
#	
#	Context "ExpectedShares "{
#		It "Returns Empty when there are no Expected Shares" {
#			
#		}
#	}
#	
#	Context "Extended Events" {
#		It "Returns Empty when there are No Extended Events Sessions Defined" {
#			
#		}
#	}
#}