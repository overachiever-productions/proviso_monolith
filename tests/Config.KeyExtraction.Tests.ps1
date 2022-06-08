Set-StrictMode -Version 1.0;

BeforeAll {
	$global:PVConfig = $null; # make sure this gets reset before all tests in here, otherwise it's global and 'leaks' previous state/configs... 
	
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "");
	
	. "$root\proviso.meta.ps1";
	Import-ProvisoTypes -ScriptRoot $root;
	
	. "$root\internal\dsl\ProvisoConfig.ps1";
	. "$root\internal\dsl\ProvisoConfig-Defaults.ps1";
	
	$script:be8c742fDefaultConfigData = $script:ProvisoConfigDefaults;
	
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
			
			{ $instances = $PVConfig.GetSqlInstanceNames("SqlServerPatches.MSSQLSERVER.TargetPatch"); } | Should -Throw;
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
