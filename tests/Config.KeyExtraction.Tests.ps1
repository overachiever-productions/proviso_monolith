Set-StrictMode -Version 1.0;

BeforeAll {
	$global:PVConfig = $null; # make sure this gets reset before all tests in here, otherwise it's global and 'leaks' previous state/configs... 
	
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "");
	
	. "$root\proviso.meta.ps1";
	Import-ProvisoTypes -ScriptRoot $root;
	
	. "$root\internal\dsl\ProvisoConfig.ps1";
	. "$root\internal\dsl\ProvisoConfig-Defaults.ps1";
	
	$script:be8c742fDefaultConfigData = $script:ProvisoConfigDefaults;
	
	filter Fake-NetworkAdaptersConfigData_0 {
		$output = @{
			Host = @{
				NetworkDefinitions = @{
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-NetworkAdaptersConfigData {
		$output = @{
			Host = @{
				NetworkDefinitions = @{
					VMNetwork = @{
						#ProvisioningPriority = 1
						#InterfaceAlias	     = "VM Network"
						
						AssumableIfNames = @(
							"Ethernet0"
							"Ethernet1"
						)
						
						IpAddress	     = "10.0.20.197/16"
						#Gateway			     = "10.0.0.1"
						PrimaryDns	     = "10.0.0.210"
						#SecondaryDns		 = "208.67.220.220"
					}
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-NetworkAdaptersConfigData_2 {
		$output = @{
			Host = @{
				NetworkDefinitions = @{
					VMNetwork = @{
						#ProvisioningPriority = 1
						#InterfaceAlias	     = "VM Network"
						
						AssumableIfNames = @(
							"Ethernet0"
							"Ethernet1"
						)
						
						IpAddress	     = "10.0.20.197/16"
						#Gateway			     = "10.0.0.1"
						PrimaryDns	     = "10.0.0.210"
						#SecondaryDns		 = "208.67.220.220"
					}
					
					Eth3	  = @{
						ProvisioningPriority = 1
						InterfaceAlias	     = "Ethernet 3"
						
						AssumableIfNames = @(
							"Ethernet3"
							"Ethernet 3"
						)
						
						IpAddress	     = "10.30.20.197/16"
						Gateway		 = "10.30.0.1"
						PrimaryDns	     = "10.30.0.210"
						SecondaryDns		 = "208.67.220.220"
					}
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-ExpectedDisksConfigData_0 {
		$output = @{
			Host = @{
				ExpectedDisks = @{

				}
			}
		}
		
		return $output;
	}
	
	filter Fake-ExpectedDisksConfigData {
		$output = @{
			Host = @{
				ExpectedDisks = @{
					
					DataDisk = @{
						#ProvisioningPriority    = 1
						
						#VolumeName			    = "D:\"
						#VolumeLabel			    = "SQLData"
						
						PhysicalDiskIdentifiers = @{
							RawSize = "60GB"
						}
					}
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-ExpectedDisksConfigData_2 {
		$output = @{
			Host = @{
				ExpectedDisks = @{
					
					DataDisk = @{
						#ProvisioningPriority    = 1
						
						#VolumeName			    = "D:\"
						#VolumeLabel			    = "SQLData"
						
						PhysicalDiskIdentifiers = @{
							RawSize = "60GB"
						}
					}
					
					BackupsDisk = @{
						VolumeName = "E:\"
						VolumeLabel = "SQLBackups"
						
						PhysicalDiskIdentifiers = @{
							RawSize = "600GB"
						}
					}
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-ExpectedSharesConfigData {
		$output = @{
			ExpectedShares = @{
				SqlBackups = @{
					SourceDirectory = "D:\SQLBackups"
					#ShareName	    = "SQLBackups"
					ReadOnlyAccess  = @(
						"OVERACHIEVER\dev-ops"
						"OVERACHIEVER\dbas"
					)
					ReadWriteAccess = @(
						#"BUILTIN\Administrators"
					)
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-SqlInstallationConfigData {
		$output = @{
			SqlServerInstallation = @{
				
				SqlExePath	      = "sqlserver_2019_dev"
				StrictInstallOnly = $false
				
				Setup			  = @{
					Version		      = "2019"
					Edition		      = "Developer"
					
					Features		  = "SQLENGINE, CONN, FullText"
					Collation		  = "SQL_Latin1_General_CP1_CI_AS"
					InstantFileInit   = $true
					
					#					InstallDirectory		  = "C:\Program Files\Microsoft SQL Server"
					#					InstallSharedDirectory    = "C:\Program Files\Microsoft SQL Server"
					#					InstallSharedWowDirectory = "C:\Program Files (x86)\Microsoft SQL Server"
					
					#					 SqlTempDbFileCount	      = "4 or half number of cores as default (whichever is larger)"
					#					 SqlTempDbFileSize		  = 1024
					#					 SqlTempDbFileGrowth	      = 256
					#					 SqlTempDbLogFileSize	  = 2048
					#					 SqlTempDbLogFileGrowth    = 256
					
					FileStreamLevel   = 0
					
					NamedPipesEnabled = $false
					TcpEnabled	      = $true
					
					LicenseKey	      = ""
				}
				
				ServiceAccounts   = @{
					SqlServiceAccountName	    = "OVERACHIEVER\sqlservice"
					SqlServiceAccountPassword   = "Pass@word1"
					AgentServiceAccountName	    = "OVERACHIEVER\sqlservice"
					AgentServiceAccountPassword = "Pass@word1"
				}
				
				SecuritySetup	  = @{
					EnableSqlAuth			    = $true
					AddCurrentUserAsAdmin	    = $true
					SaPassword				    = "Pass@word1"
					MembersOfSysAdmin		    = @(
						"BuiltIn\Administrators"
					)
				}
				
				SqlServerDefaultDirectories = @{
					SqlDataPath    = "D:\SQLData"
					SqlBackupsPath = "D:\SQLBackups"
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-SqlPatchesConfigData {
		$output = @{
			SqlServerPatches = @{
				"MSSQLSERVER" = @{
					TargetCU = "SQLServer2019-KB5011644-x64_cu16.exe"
				}
				"X99" = @{
					TargetCU = "SQLServer2019-KB5011644-x64_cu16.exe";
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-ExtendedEventsConfigData_0 {
		$output = @{
			ExtendedEvents = @{
				DisableTelemetry = $true
				
				Sessions		 = @{
					
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-ExtendedEventsConfigData {
		$output = @{
			ExtendedEvents = @{
				DisableTelemetry = $true
				
				Sessions		 = @{
					BlockedProcesses = @{
						SessionName	    = "blocked_processes"
						StartWithSystem = $true
					}
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-ExtendedEventsConfigData_2 {
		$output = @{
			ExtendedEvents = @{
				DisableTelemetry = $true
				
				Sessions		 = @{
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
		
		return $output;
	}
	
	filter Fake-ExtendedEventsConfigData_Multi {
		$output = @{
			ExtendedEvents = @{
				"MSSQLSERVER" = @{
					DisableTelemetry = $true
					
					Sessions		 = @{
						BlockedProcesses = @{
							SessionName	    = "blocked_processes"
							StartWithSystem = $true
						}
						
						CorrelatedSpills = @{
							SessionName = "correlated_spills"
						}
					}
				}
				"XX9" = @{
					DisableTelemetry = $true
					
					Sessions		 = @{
						Deadlocks = @{
							SessionName	    = "deadlocks_only"
							StartWithSystem = $true
						}
					}
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-NetworkSharesConfigData_0 {
		$output = @{
			ExpectedShares = @{
			}
		}
		
		return $output;
	}
	
	filter Fake-NetworkSharesConfigData {
		$output = @{
			ExpectedShares = @{
				SqlBackups = @{
					SourceDirectory = "D:\SQLBackups"
					ShareName	    = "SQLBackups"
					ReadOnlyAccess  = @(
						#				"OVERACHIEVER\dev-ops"
						#				"OVERACHIEVER\dbas"
					)
					ReadWriteAccess = @(
						"BUILTIN\Administrators"
					)
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-NetworkSharesConfigData_2 {
		$output = @{
			ExpectedShares = @{
				SqlBackups = @{
					SourceDirectory = "D:\SQLBackups"
					ShareName	    = "SQLBackups"
					ReadOnlyAccess  = @(
					)
					ReadWriteAccess = @(
						"BUILTIN\Administrators"
					)
				}
				Traces	   = @{
					SourceDirectory = "D:\Traces"
					ShareName	    = "SQLTraces"
					ReadWriteAccess = @(
						"BUILTIN\Administrators"
					)
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-DataCollectorSetsConfigData_0 {
		$output = @{
			DataCollectorSets = @{
			}
		}
		
		return $output;
	}
	
	filter Fake-DataCollectorSetsConfigData {
		$output = @{
			DataCollectorSets = @{
				
				Consolidated = @{
					Enabled			      = $true
					XmlDefinition		  = "" # if NOT explicitly specified will be <GroupName>.xml - e.g., Consolidated.xml
					EnableStartWithOS	  = $true
					DaysWorthOfLogsToKeep = 45 # if empty then NO cleanup... 
				}
			}
		}
		
		return $output;
	}
	
	filter Fake-DataCollectorSetsConfigData_2 {
		$output = @{
			DataCollectorSets = @{
				
				Consolidated = @{
					Enabled			      = $true
					XmlDefinition		  = "" # if NOT explicitly specified will be <GroupName>.xml - e.g., Consolidated.xml
					EnableStartWithOS	  = $true
					DaysWorthOfLogsToKeep = 45 # if empty then NO cleanup... 
				}
				
				Mirroring    = @{
					Enabled			      = $true
					XmlDefinition		  = ""
					EnableStartWithOS	  = $true
					DaysWorthOfLogsToKeep = "20"
				}
			}
		}
		
		return $output;
	}
	
	#	filter Fake-xyzConfigData {
	#		
	#	}
	
	# FUNC Stubs (to facilitate mocks):
	filter Get-WindowsCoreCount {
	}
	filter Get-SqlServerDefaultDirectoryLocation {
		param ([string]$InstanceName,
			[string]$SqlDirectory)
	};
}

Describe "Get-ConfigurationEntry Tests" {
	Context "Dependencies Tests" {
		It "Throws when `$PVConfig has Not Been Set" {
			{ Get-ConfigurationEntry -Key "Host.NetworkDefinitions.VMNetwork.InterfaceAlias"; } | Should -Throw;
		}
	}
	
	Context "Error Handling" {
		#Set-ConfigTarget -ConfigData (Fake-NetworkAdaptersConfigData);
	}
}

Describe "Get-KeyValue Tests" {
	Context "Error Handling" {
		It "Throws when Requested-Key is Invalid" {
			Set-ConfigTarget -ConfigData (Fake-NetworkAdaptersConfigData) -Strict:$false;
			{
				$PVConfig.GetValue("Host.MachineName");
			} | Should -Throw;
		}
	}
	
	Context "Core Default values Processing" {
		It "Does Not Return Defaults when Defaulst Are Disabled" {
			Set-ConfigTarget -ConfigData (Fake-NetworkAdaptersConfigData) -AllowDefaults:$false -Strict:$false;
			
			$PVConfig.GetValue("Host.NetworkDefinitions.VMNetwork.InterfaceAlias") | Should -BeNullOrEmpty;
		}
		
		It "Returns Explicit Values when Present" {
			Set-ConfigTarget -ConfigData (Fake-NetworkAdaptersConfigData) -Strict:$false;
			
			$PVConfig.GetValue("Host.NetworkDefinitions.VMNetwork.IpAddress") | Should -Be "10.0.20.197/16";
		}
		
		It "Returns Defaults When Allowed and No Explicit Value" {
			Set-ConfigTarget -ConfigData (Fake-NetworkAdaptersConfigData) -Strict:$false;
			
			$PVConfig.GetValue("Host.NetworkDefinitions.VMNetwork.ProvisioningPriority") | Should -Be 5;
		}
		
		It "Returns Null/Empty when No Explicit Value and Default is Empty" {
			Set-ConfigTarget -ConfigData (Fake-NetworkAdaptersConfigData) -Strict:$false;
			
			$PVConfig.GetValue("Host.NetworkDefinitions.VMNetwork.SecondaryDns") | Should -BeNullOrEmpty;
		}
		
		It "Throws when No Explicit Value and Default is Default-Prohibited" {
			Set-ConfigTarget -ConfigData (Fake-NetworkAdaptersConfigData) -Strict:$false;
			
			{ $PVConfig.GetValue("Host.NetworkDefinitions.VMNetwork.Gateway");	} | Should -Throw;
		}
	}
	
	Context "Parent-Defaults Correctly Traverse Key Nodes" {
		It "Returns Parent-Value for Parent-Default for Host.Disks" {
			Set-ConfigTarget -ConfigData (Fake-ExpectedDisksConfigData) -Strict:$false;
			
			$PVConfig.GetValue("Host.ExpectedDisks.DataDisk.VolumeLabel") | Should -Be "DataDisk";
		}
		
		It "Returns Parent-Value for Parent-Default for Host.Adapters" {
			Set-ConfigTarget -ConfigData (Fake-NetworkAdaptersConfigData) -Strict:$false;
			
			$PVConfig.GetValue("Host.NetworkDefinitions.VMNetwork.InterfaceAlias") | Should -Be "VMNetwork";
		}
		
		It "Returns Parent-Value for Parent-Default for ExpectedShare Names" {
			Set-ConfigTarget -ConfigData (Fake-NetworkAdaptersConfigData) -Strict:$false;
			
			$PVConfig.GetValue("ExpectedShares.SqlBackups.ShareName") | Should -Be "SqlBackups";
		}
		
		#		It "Returns Parent-Value for Parent-Default for ExtendedEvent Session Names" {
		#			
		#		}
		
		#		It "Returns Parent-Value for Parent-Default for xxxx" {
		#			
		#		}
	}
	
	Context "Dynamic Defaults Tests" {
		It "Returns Function Lookup-Results for Dynamic-TempDbFileCounts-Default" {
			Mock Get-WindowsCoreCount {
				return 5; # goofy/odd number is easy to test. 
			}
			
			Set-ConfigTarget -ConfigData (Fake-SqlInstallationConfigData) -Strict:$false;
			
			$PVConfig.GetValue("SqlServerInstallation.MSSQLSERVER.Setup.SqlTempDbFileCount") | Should -Be 4; # this is the MAX for the DEFAULT... 
		}
		
		It "Returns Function Lookup-Results for Dynamic-SqlDefaultDirectories-Default" {
			Mock Get-SqlServerDefaultDirectoryLocation {
				return "X:\TestDirectory";
			}
			
			Set-ConfigTarget -ConfigData (Fake-SqlInstallationConfigData) -Strict:$false;
			
			$PVConfig.GetValue("SqlServerInstallation.MSSQLSERVER.SqlServerDefaultDirectories.SqlLogsPath") | Should -Be "X:\TestDirectory";
		}
		
		It "Returns CollectorSet Parent for Dynamic-Name-Default" {
			Set-ConfigTarget -ConfigData (Fake-DataCollectorSetsConfigData) -Strict:$false;
			
			
			$PVConfig.GetValue("DataCollectorSets.Consolidated.Name") | Should -Be "Consolidated";
			
		}
	}
	
	#Context "Dynamic-XXX Defaults xxxx" {
	#	
	#}
	#
	#Context "Dynamic-XXX Defaults xxxx" {
	#	
	#}
}

Describe "Get-SqlInstanceNames Tests" {
	Context "Error Handling" {
		It "Throws on invalid Keys" {
			Set-ConfigTarget -ConfigData (Fake-SqlPatchesConfigData) -Strict:$false;
			
			{
				$instances = $PVConfig.GetSqlInstanceNames("SqlServerPatches.MSSQLSERVER.TargetPatch");
			} | Should -Throw;
		}
	}
	
	Context "Behavior Tests" {
		It "Handles Implicit Keys" {
			Set-ConfigTarget -ConfigData (Fake-SqlPatchesConfigData) -Strict:$false;
			
			$instances = $PVConfig.GetSqlInstanceNames("SqlServerPatches.TargetPatch"); # actually, this is being handled on ACCIDENT... (it's initially treating TargetPatch as an "instanceName" then... getting all instance names from the 'actual' config)
			$instances.Count | Should -Be 2;
		}
		
		It "Handles Multiple Instances" {
			Set-ConfigTarget -ConfigData (Fake-SqlPatchesConfigData) -Strict:$false;
			
			$instances = $PVConfig.GetSqlInstanceNames("SqlServerPatches"); # actually, this is being handled on ACCIDENT... 
			$instances.Count | Should -Be 2;
		}
	}
}

Describe "Get-ObjectInstanceNames Tests" {
	
	Context "ExpectedDisks Tests" {
		
		It "Correctly Reports No Disks" {
			Set-ConfigTarget -ConfigData (Fake-ExpectedDisksConfigData_0) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("Host.ExpectedDisks")).Count | Should -Be 0;
		}
		
		It "Correctly Reports Single Disk" {
			Set-ConfigTarget -ConfigData (Fake-ExpectedDisksConfigData) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("Host.ExpectedDisks")).Count | Should -Be 1;
			($PVConfig.GetObjectInstanceNames("Host.ExpectedDisks")) -contains "DataDisk" | Should -BeTrue;
		}
		
		It "Does NOT care about child keys as part of Key" {
			Set-ConfigTarget -ConfigData (Fake-ExpectedDisksConfigData) -Strict:$false;
			
			# Same test as above, but ... DataDisk SOMEHOW got thrown into the key being requested... 
			($PVConfig.GetObjectInstanceNames("Host.ExpectedDisks.DataDisk")).Count | Should -Be 1;
			
			# Same, but ... 'yet another child key' has somehow been added (i.e., testing that the LEADING part of the key is good enough and everything AFTER that is ignored)
			($PVConfig.GetObjectInstanceNames("Host.ExpectedDisks.DataDisk.VolumeName")).Count | Should -Be 1;
		}
		
		It "Does NOT care about {~ANY~} nodes as part of Key" {
			Set-ConfigTarget -ConfigData (Fake-ExpectedDisksConfigData_2) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("Host.ExpectedDisks.{~ANY~}")).Count | Should -Be 2;
			
			($PVConfig.GetObjectInstanceNames("Host.ExpectedDisks.{~ANY~}")) -contains "DataDisk" | Should -BeTrue;
			($PVConfig.GetObjectInstanceNames("Host.ExpectedDisks.{~ANY~}")) -contains "BackupsDisk" | Should -BeTrue;
		}
		
		It "Correctly Reports Multiple Disks" {
			Set-ConfigTarget -ConfigData (Fake-ExpectedDisksConfigData_2) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("Host.ExpectedDisks")).Count | Should -Be 2;
			
			($PVConfig.GetObjectInstanceNames("Host.ExpectedDisks")) -contains "DataDisk" | Should -BeTrue;
			($PVConfig.GetObjectInstanceNames("Host.ExpectedDisks")) -contains "BackupsDisk" | Should -BeTrue;
		}
	}
	
	Context "NetworkAdapter Tests" {
		It "Correctly Reports No Adapters" {
			Set-ConfigTarget -ConfigData (Fake-NetworkAdaptersConfigData_0) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("Host.NetworkDefinitions")).Count | Should -Be 0;
		}
		
		It "Correctly Reports Single Adapter" {
			Set-ConfigTarget -ConfigData (Fake-NetworkAdaptersConfigData) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("Host.NetworkDefinitions")).Count | Should -Be 1;
		}
		
		It "Correctly Reports Multiple Adapters" {
			Set-ConfigTarget -ConfigData (Fake-NetworkAdaptersConfigData_2) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("Host.NetworkDefinitions")).Count | Should -Be 2;
		}
	}
	
	Context "NetworkShares Tests" {
		It "Correctly Reports No Shares" {
			Set-ConfigTarget -ConfigData (Fake-NetworkSharesConfigData_0) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("ExpectedShares")).Count | Should -Be 0;
		}
		
		It "Correctly Reports Single Share" {
			Set-ConfigTarget -ConfigData (Fake-NetworkSharesConfigData) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("ExpectedShares")).Count | Should -Be 1;
		}
		
		It "Correctly Reports Multiple Shares" {
			Set-ConfigTarget -ConfigData (Fake-NetworkSharesConfigData_2) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("ExpectedShares")).Count | Should -Be 2;
			($PVConfig.GetObjectInstanceNames("ExpectedShares")) -contains "SqlBackups" | Should -BeTrue;
		}
	}
	
	Context "DataCollectorSet Tests" {
		It "Correctly Reports No DataCollectorSets" {
			Set-ConfigTarget -ConfigData (Fake-DataCollectorSetsConfigData_0) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("DataCollectorSets")).Count | Should -Be 0;
		}
		
		It "Correctly Reports Single DataCollectorSet" {
			Set-ConfigTarget -ConfigData (Fake-DataCollectorSetsConfigData) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("DataCollectorSets")).Count | Should -Be 1;
		}
		
		It "Correctly Reports Multiple DataCollectorSets" {
			Set-ConfigTarget -ConfigData (Fake-DataCollectorSetsConfigData_2) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("DataCollectorSets")).Count | Should -Be 2;
			($PVConfig.GetObjectInstanceNames("DataCollectorSets")) -contains "Mirroring" | Should -BeTrue;
		}
	}
	
	Context "ExtendedEvents Sessions Tests" {
		It "Correctly Reports No XE Sessions" {
			Set-ConfigTarget -ConfigData (Fake-ExtendedEventsConfigData_0) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("ExtendedEvents.Sessions")).Count | Should -Be 0;
		}
		
		It "Correctly Reports Single ExtendedEvents Session" {
			Set-ConfigTarget -ConfigData (Fake-ExtendedEventsConfigData) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("ExtendedEvents.Sessions")).Count | Should -Be 1;
			($PVConfig.GetObjectInstanceNames("ExtendedEvents.Sessions")) -contains "BlockedProcesses" | Should -BeTrue;
		}
		
		It "Correctly Reports Multiple ExtendedEvents Sessions" {
			Set-ConfigTarget -ConfigData (Fake-ExtendedEventsConfigData_2) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("ExtendedEvents.Sessions")).Count | Should -Be 2;
			($PVConfig.GetObjectInstanceNames("ExtendedEvents.Sessions")) -contains "BlockedProcesses" | Should -BeTrue;
			($PVConfig.GetObjectInstanceNames("ExtendedEvents.Sessions")) -contains "CorrelatedSpills" | Should -BeTrue;
		}
		
		It "Ignores InstanceNames in Keys" {
			Set-ConfigTarget -ConfigData (Fake-ExtendedEventsConfigData) -Strict:$false;
			
			# Shouldn't really ever 'call' this func with the name in the key itself, BUT, the code SHOULD simply ignore it (and favor explicit instance as param)
			($PVConfig.GetObjectInstanceNames("ExtendedEvents.MSSQLSERVER.Sessions")).Count | Should -Be 1;
			($PVConfig.GetObjectInstanceNames("ExtendedEvents.MSSQLSERVER.Sessions")) -contains "BlockedProcesses" | Should -BeTrue;
		}
		
		It "Favors InstanceName As Argument" {
			Set-ConfigTarget -ConfigData (Fake-ExtendedEventsConfigData) -Strict:$false;
			
			# SHOULDN'T happen that we somehow have an explicit name in the KEY itself. But, even IF it does happen, the func should ignore it in FAVOR of the arg.
			($PVConfig.GetObjectInstanceNames("ExtendedEvents.X3.Sessions", "MSSQLSERVER")).Count | Should -Be 1;
		}
		
		It "Correctly Distinguishes Between SqlServerInstance Sessions" {
			Set-ConfigTarget -ConfigData (Fake-ExtendedEventsConfigData_Multi) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("ExtendedEvents.Sessions", "XX9")).Count | Should -Be 1;
			($PVConfig.GetObjectInstanceNames("ExtendedEvents.Sessions", "XX9")) -contains "Deadlocks" | Should -BeTrue;
		}
		
		
		It "Correctly Reports Multiple ExtendedEvents Sessions" {
			Set-ConfigTarget -ConfigData (Fake-ExtendedEventsConfigData_Multi) -Strict:$false;
			
			($PVConfig.GetObjectInstanceNames("ExtendedEvents.Sessions", "XX9")).Count | Should -Be 1;
			
			($PVConfig.GetObjectInstanceNames("ExtendedEvents.Sessions", "MSSQLSERVER")).Count | Should -Be 2;
		}
	}
}
