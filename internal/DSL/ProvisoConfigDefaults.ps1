Set-StrictMode -Version 1.0;

[PSCustomObject]$script:ProvisoConfigDefaults = [PSCustomObject]@{
	
	Host = @{
		
		TargetServer	    = "{~DEFAULT_PROHIBITED~}"
		TargetDomain	    = "{~DEFAULT_PROHIBITED~}"
		
		AllowGlobalDefaults = $false
		
		NetworkDefinitions  = @{
			"{~ANY~}" = @{
				ProvisioningPriority = 5
				InterfaceAlias	     = "{~PARENT~}"
			}
		}
		
		LocalAdministrators = @(
		)
		
		WindowsPreferences  = @{
			DvdDriveToZ				     = $false
			OptimizeExplorer			 = $true
			DisableServerManagerOnLaunch = $true
			SetPowerConfigHigh		     = $true
			DisableMonitorTimeout	     = $false
			EnableDiskPerfCounters	     = $true
		}
		
		RequiredPackages    = @{
			WsfcComponents								   = $false
			NetFxForPre2016InstancesRequired			   = $false
			AdManagementFeaturesforPowershell6PlusRequired = $false
		}
		
		LimitHostTls1dot2Only = $false
		
		FirewallRules	    = @{
			EnableFirewallForSqlServer		    = $false
			EnableFirewallForSqlServerDAC	    = $false
			EnableFirewallForSqlServerMirroring = $false
			
			EnableICMP						    = $false
		}
		
		ExpectedDisks	    = @{
			"{~ANY~}" = @{
				ProvisioningPriority = 5
				VolumeLabel		     = "~{PARENT}~"
			}
		}
	}
	
	ExpectedDirectories = @{
		
		"{~ANY~}" = @{
			
			VirtualSqlServerServiceAccessibleDirectories = @()
			
			RawDirectories							     = @()
		}
	}
	
	ExpectedShares = @{
		"{~ANY~}" = @{
			ShareName	   = "{~PARENT~}"
			ReadOnlyAccess = @()
			ReadWriteAccess = @()
		}
	}
	
	SqlServerInstallation = @{
		
		"{~ANY~}" = @{
			SqlExePath	      = "{~DEFAULT_PROHIBITED~}"
			StrictInstallOnly = $true
			
			Setup			  = @{
				Version			       = ""
				Edition			       = ""
				
				Features			   = "{~DEFAULT_PROHIBITED~}"
				Collation			   = "SQL_Latin1_General_CP1_CI_AS"
				InstantFileInit		      = $true
				
				InstallDirectory		  = "{~DEFAULT_PROHIBITED~}"
				InstallSharedDirectory    = "{~DEFAULT_PROHIBITED~}"
				InstallSharedWowDirectory = "{~DEFAULT_PROHIBITED~}"
				
				SqlTempDbFileCount	   = "{~DYNAMIC~}" # 4 or .5 * core-count (whichever is larger)
				SqlTempDbFileSize	   = 1024
				SqlTempDbFileGrowth    = 256
				SqlTempDbLogFileSize   = 2048
				SqlTempDbLogFileGrowth = 256
				
				FileStreamLevel	       = 0
				
				NamedPipesEnabled	   = $false
				TcpEnabled			   = $true
				
				LicenseKey			   = ""
			}
			
			SecuritySetup	  = @{
				EnableSqlAuth		  = $false
				AddCurrentUserAsAdmin = $false
				SaPassword		      = "{~DEFAULT_PROHIBITED~}"
				MembersOfSysAdmin	  = @(
				)
			}
			
			# NOTE: Get-SqlServerDefaultServiceAccount will eventually handle these defaults: 
			#ServiceAccounts   = @{}
			
			# NOTE: Get-SqlServerDefaultDirectoryLocation will eventually address this... (for defaults)
			#SqlServerDefaultDirectories = @{}
		}
		
		MSSQLSERVER = @{
			SqlExePath	      = "{~DEFAULT_PROHIBITED~}"
			StrictInstallOnly = $true
			
			Setup			  = @{
				Version			       = ""
				Edition			       = ""
				
				Features			   = "{~DEFAULT_PROHIBITED~}"
				Collation				  = "SQL_Latin1_General_CP1_CI_AS"
				InstantFileInit		      = $true
				
				InstallDirectory		  = "C:\Program Files\Microsoft SQL Server"
				InstallSharedDirectory    = "C:\Program Files\Microsoft SQL Server"
				InstallSharedWowDirectory = "C:\Program Files (x86)\Microsoft SQL Server"
				
				SqlTempDbFileCount	   = "{~DYNAMIC~}"
				SqlTempDbFileSize	   = 1024
				SqlTempDbFileGrowth    = 256
				SqlTempDbLogFileSize   = 2048
				SqlTempDbLogFileGrowth = 256
				
				FileStreamLevel	       = 0
				
				NamedPipesEnabled	   = $false
				TcpEnabled			   = $true
				
				LicenseKey			   = ""
			}
			
			# Handled by: Get-SqlServerDefaultServiceAccount
			ServiceAccounts   = @{
				SqlServiceAccountName	    = "NT SERVICE\MSSQLSERVER"
				SqlServiceAccountPassword   = ""
				AgentServiceAccountName	    = "NT SERVICE\SQLSERVERAGENT"
				AgentServiceAccountPassword = ""
				FullTextServiceAccount	    = "NT SERVICE\MSSQLFDLauncher"
				FullTextServicePassword	    = ""
			}
			
			SecuritySetup	  = @{
				EnableSqlAuth			    = $true
				AddCurrentUserAsAdmin	    = $false
				SaPassword				    = "{~DEFAULT_PROHIBITED~}"
				MembersOfSysAdmin		    = @(
				)
			}
			
			#Handled by: Get-SqlServerDefaultDirectoryLocation
			SqlServerDefaultDirectories = @{
#				InstallSqlDataDir 	= "D:\SQLData"
#				SqlDataPath    		= "D:\SQLData"
#				SqlLogsPath    		= "D:\SQLData"
#				SqlBackupsPath 		= "D:\SQLBackups"
#				TempDbPath	      	= "D:\SQLData"
#				TempDbLogsPath    	= "D:\SQLData"
			}
		}
	}
	
	SqlServerConfiguration = @{
		
		"{~ANY~}" = @{
			LimitSqlServerTls1dot2Only = $false
			GenerateSPN			       = $false
			DisableSaLogin			   = $false
			DeployContingencySpace	   = $false
			
			EnabledUserRights		   = @{
				LockPagesInMemory			  = $false
				PerformVolumeMaintenanceTasks = $false
			}
			
			TraceFlags				   = @(
				3326
				7745
				7752
			)
		}
	}
	
	SqlServerPatches = @{
		
		"{~ANY~}" = @{
		}
	}
	
	AdminDb = @{
		
		"{~ANY~}" = @{
			
			Deploy		     = $false
			
			InstanceSettings = @{
				Enabled					    = $false # too much of a custom concern to enable by DEFAULT. 
				MAXDOP					    = 2
				CostThresholdForParallelism = 40
				OptimizeForAdHocQueries	    = $true
			}
			
			DatabaseMail	 = @{
				Enabled					    = $true
				SendTestEmailUponCompletion = $true
			}
			
			HistoryManagement = @{
				Enabled = $true
			}
			
			DiskMonitoring   = @{
				Enabled = $true
			}
			
			Alerts		     = @{
				IOAlertsEnabled	       = $true
				IOAlertsFiltered	   = $false
				SeverityAlertsEnabled  = $true
				SeverityAlertsFiltered = $true
			}
			
			IndexMaintenance = @{
				Enabled = $false
			}
			
			ConsistencyChecks = @{
				Enabled = $false
			}
			
			BackupJobs	     = @{
				Enabled = $true
			}
			
			RestoreTestJobs  = @{
				Enabled = $false
			}
			
			SqlEncryptionKeys = @{
				
				CreateMasterEncryptionKey    = $true
				MasterEncryptionKeyPassword  = "" # allow this to be empty/blank (i.e., create something dynamic)
				
				BackupSuchAndSuchCertificate = @{
					#					# 0 - N certs go here - where each entry is the NAME of the cert to deploy... 
					#					CertXyzPath							       = "so on"
					#					XyzOtherDetail							   = "blah"
					#					BackupPathToShoveTheTHingIntoAfterCreation = "etc"
				}
				
				TDECertificateOrAnotherCertificateHere = @{
					#					InfoHereToCreateFromScratch = "or whatever"
				}
			}
		}
	}
	
	DataCollectorSets = @{
		Enabled   = $false
		
		"{~ANY~}" = @{
			EnableStartWithOS	  = $false
			DaysWorthOfLogsToKeep = 180
		}
	}
	
	ExtendedEvents = @{
		DisableTelemetry = $true
		
		"{~ANY~}"	     = @{
		}
	}
	
	SqlServerManagementStudio = @{
		InstallSsms	       = $false
		IncludeAzureStudio = $false
	}
	
	ResourceGovernor = @{
		"{~ANY~}" = @{
		}
	}
	
	ClusterConfiguration = @{
		ClusterType = "NONE"
	}
	
	AvailabilityGroups = @{
		
		EnabledOrStrictEnabled = "probably need 2x keys/entries here... but idea is a) configure AG membership or not? and b) what if ... we find the server as PART of an AG that's NOT defined below?"
		
		MirroringEndpoint	   = @{
			Enabled						    = $false
			PortNumber					    = 5022
			Name						    = ""
			AllowedOwnersConnectingAccounts = @(
			)
		}
		
		SynchronizationChecks  = @{
			AdminDbStuffHere = @{
				AddPartners		       = ""
				SyncCheckJobs		   = ""
				AddFailoverProcessing  = ""
				AddDisabledJobCategory = ""
			}
		}
		
		"{~ANY~}"			   = @{
			Action   = "NONE"
			
			Replicas = @(
			)
			
			Seeding  = @{
			}
			
			Databases = @(
			)
			
			Listener = @{
				Name			    = ""
				PortNumber		    = 1433
				IPs				    = @(
				)
				
				ReadOnlyRounting    = @(
				)
				
				GenerateClusterSPNs = $false
			}
		}
	}
	
	CustomSqlScripts = @{
		"{~ANY~}" = @{
			Deploy = $false
		}
	}
}