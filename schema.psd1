@{
	
	TargetServer	    = "AWS-SQL-1A"
	TargetDomain		= ""
	
	NetworkDefinitions = @{
		
		# allows multiple adapters. 
		VMNetwork = @{
			ProvisioningPriority = 1
			
			AssumableIfNames	 = @(
				"Ethernet0"
				"Ethernet1"
			) 
			InterfaceAlias 	 = "VM Network"
			
			IpAddress		     = "10.10.30.101/16"
			Gateway			     = "10.10.0.1"
			PrimaryDns		     = "10.0.0.1"
			SecondaryDns		 = "208.67.222.222"
		}
	}

	WindowsPreferences = @{
		DvdDriveToZ				     = $true
		OptimizeExplorer			 = $true
		DisableServerManagerOnLaunch = $true
		SetPowerConfigHigh		     = $true
		DisableMonitorTimeout        = $true
		EnableDiskPerfCounters	     = $true
	}
	
	RequiredPackages = @{
		WsfcComponents = $true
		NetFxForPre2016InstancesRequired = $false
	}
	
	LimitHostTls1dot2Only = $true
	
	FirewallRules	   = @{
		EnableFirewallForSqlServer		    = $true
		EnableFirewallForSqlServerDAC	    = $true
		EnableFirewallForSqlServerMirroring = $true
		
		EnableICMP						    = $true
	}
	
	ExpectedDisks = @{
		
		DataDisk = @{
			ProvisioningPriority    = 1
			
			VolumeName			    = "D:\"
			VolumeLabel			    = "SQLData"
			
			PhysicalDiskIdentifiers = @{
				RawSize = "40GB"
			}
		}
		
		BackupsDisk = @{
			ProvisioningPriority    = 3
			
			VolumeName			    = "E:\"
			VolumeLabel			    = "SQLBackups"
			
			PhysicalDiskIdentifiers = @{
				RawSize = "60GB"
			}
		}
		
		TempdbDisk = @{
			
			VolumeName			    = "F:\"
			VolumeLabel			    = "SQLTempDB"
			IsEphmeral			    = 1
			
			PhysicalDiskIdentifiers = @{
				RawSize    = "30GB"
				DiskNumber = "3"
				DeviceId   = "xvdd"
			}
		}
	}
	
	ExpectedDirectories   = @{
		
		SqlServerInstanceName = "MSSQLSERVER" # scripts ALWAYS assume MSSQLSERVER ... but this directive exists to enable non-default-instance names via config
		
		# Directories that NT SERVICE\MSSQLSERVER can access (full perms)
		VirtualSqlServerServiceAccessibleDirectories = @(
			"D:\SQLData"
			"D:\Traces"
			"E:\SQLBackups"
			"F:\SQLTempDB"
			"F:\Traces"
		)
		
		# Additional/Other Directories - but no perms granted to SQL Server service.
		RawDirectories							     = @(
			"D:\SampleDirectory"
			"E:\Archived"
		)
	}
		
	ExpectedShares	      = @{
		SqlBackups = @{
			SourceDirectory = "E:\SQLBackups"
			ShareName	    = "SQLBackups"
			ReadOnlyAccess  = @()
			ReadWriteAccess = @(
				"AWS\sqlservice"
			)
		}
	}
	
	SqlServerInstallation = @{
		
		SqlExePath		     = "sqlserver_2019_dev"  
		SqlIniFile			 = "2019_STANDARD_INSTALL"
		StrictInstallOnly    = $true  
		
		ServiceAccounts	     = @{
			SqlServiceAccountName	   		= "xyz or group managed service account here"
			SqlServiceAccountPassword 		= "probably safe-ish to store this here... but, better off to have an option to run lookups and some nomenclature/specification on how to grab that"
			AgentServiceAccountName 		= "optional. if not present, defaults to ServiceAccountName"
			AgentServiceAccountPassword 	= "OPTIONAL. as with ServiceAccountPassword, can be empty if/when service-accounts are NT SERVICE\xxx accounts... "
		}
		
		SecuritySetup	     = @{
			EnableSqlAuth			    = $true
			AddCurrentUserAsAdmin	    = $true
			SaPassword				    = "12345"
			MembersOfSysAdmin		    = @(
				"domain\techops"
				"BuiltIn\Administrators"
			)
		}
		
		SqlServerDefaultDirectories = @{
			SqlDataPath    = "D:\SQLData"
			SqlLogsPath    = "D:\SQLData"
			SqlBackupsPath = "D:\SQLBackups"
			TempDbPath	   = "D:\SQLData"
		}
		
		LicenseKey		     = ""
	}
	
	SqlServerConfiguration = @{
		
		LimitSqlServerTls1dot2Only = $true
		GenerateSPN			       = $true # vNEXT - see PRO-43
		DisableSaLogin			   = $false 
		DeployContingencySpace	   = $true;
		
		EnabledUserRights		   = @{
			LockPagesInMemory			  = $true
			PerformVolumeMaintenanceTasks = $true
		}
		
		TraceFlags				   = @(
			3226
			7745
			7752
		)
	}
	
	AdminDb = @{
		
		Deploy		      				= $true
		OverrideSource 					= "assets/admindb_latest.sql"		
		
		ConfigureInstance		   = @{
			MAXDOP					    	= 2
			MaxServerMemoryGBs		    	= 502
			CostThresholdForParallelism 	= 40
			OptimizeForAdHocQueries 		= $true   # Default is TRUE - i.e., only way this'll be false is if there's a config entry that explicitly sets to $false
		}
		
		DatabaseMail			   = @{
			Enabled					    = $true
			OperatorEmail			    = "mike@overachiever.net"
			SmtpAccountName			    = "AWS - East"
			SmtpOutgoingEmailAddress    = "alerts@overachiever.net"
			SmtpServerName			    = "email-smtp.us-east-1.amazonaws.com"
			SmtpPortNumber			    = 587
			SmtpRequiresSSL			    = $true
			SmtpAuthType				= "BASIC"				# OPTIONS: { BASIC | WINDOWS | ANONYMOUS } - defaults to BASIC
			SmptUserName			    = "AKIAI2QUP43VN5VRF73Q"
			SmtpPassword			    = "AkbYdzRcUiM1BqsqcCLbRi3fgE7pvRXxxxxxxxHAr6KKE"
			SendTestEmailUponCompletion = $true
		}
		
		HistoryManagement    = @{
			Enabled			      		= $true
			SqlServerLogsToKeep  		= 18
			AgentJobHistoryRetention 	= "6 weeks"
			BackupHistoryRetention		= "6 weeks"
			EmailHistoryRetention 		= "6 months"
			xyzHistoryRetention   		= "2 months"
		}
		
		DiskMonitoring	   = @{
			Enabled			       = $true
			WarnWhenFreeGBsGoBelow = "32"
		}
		
		Alerts		       = @{
			IOAlertsEnabled	       = $true
			IOAlertsFiltered	   = $false # for example... 
			SeverityAlertsEnabled  = $true
			SeverityAlertsFiltered = $true
		}
		
		IndexMaintenance  = @{
			Enabled 					= $true
			DailyJobRunsOnDays			= "M,W,F"
			WeekendJobRunsOnDays		= "Su"
			StartTime		     		= "22:30:00"
			TimeZoneForUtcOffset 		= "Central Standard Time"
			JobsNamePrefix				= "Index Maintenance"
			JobsCategoryName			= "Database Maintenance"
			OperatorToAlertOnErrors     = "Alerts"
		}
		
		ConsistencyChecks = @{
			Enabled 						= $true 
			ExecutionDays 					= "M, W, F, Su" 
			StartTime   					= "04:10:00"
			Targets							= "{USER}"
			IncludeExtendedLogicalChecks	= $false
			Exclusions 						= ""
			Priorities						= ""
			TimeZoneForUtcOffset 			= "Central Standard Time"
			JobName		    				= "Database Consistency Checks"
			JobCategoryName	    			= "Database Maintenance"
			Operator			 			= "Alerts"
			JobEmailPrefix					= "[Database Corruption Checks] "
			Profile							= "General"
		}
		
		BackupJobs				   = @{
			Enabled					   		= $true
			UserDatabasesToBackup	   		= "{USER}"
			UserDbsToExclude		   		= ""
			CertificateName			   		= ""
			BackupDirectory 				= "{DEFAULT}"
			CopyToDirectory					= ""
			SystemBackupRetention 			= "4 days"
			CopyToSystemBackupRetention		= ""
			UserBackupRetention 			= "3 days"
			CopyToUserBackupRetention 		= ""
			LogBackupRetention 				= "73 hours"
			CopyToLogBackupRetention		= ""
			AllowForSecondaries 			= $false
			SystemBackupsStart 				= "18:50:00"
			UserBackupsStart 				= "02:00:00"
			LogBackupsStart 				= "00:02:00"
			LogBackupsEvery 				= "10 minutes"
			DiffBackupsStart 				= ""
			DiffBackupsEvery		    	= ""
			TimeZoneForUtcOffset			= ""
			JobsNamePrefix					= "Database Backups - "
			JobsCategoryName				= "Backups"
			Operator 						= "Alerts"
			Profile 						= "General"
		}
		
		RestoreTestJobs		       = @{
			Enabled				      	= $true
			JobName						= "Database Backups - Regular Restore Tests"
			JobStartTime				= "22:30:00"
			TimeZoneForUtcOffset 		= ""
			JobCategoryName 			= "Backups"
			AllowForSecondaries 		= $false 
			DatabasesToRestore   		= "{READ_FROM_FILESYSTEM}"
			DatabasesToExclude   		= ""
			Priorities 					= ""
			BackupsRootPath 			= "{DEFAULT}"
			RestoreDataPath  			= "{DEFAULT}"
			RestoreLogsPath  			= "{DEFAULT}"
			RestoredDbNamePattern 		= "{0}_s4test"
			AllowReplace 				= ""
			RpoThreshold 				= "24 hours"
			DropDbsAfterRestore 		= $true 
			MaxFailedDrops 				= 3
			Operator			  		= "Alerts"
			Profile			      		= "General"
			JobEmailPrefix 				= "[RESTORE TEST] "
			
		}
		
		SqlEncryptionKeys = @{
			
			CreateMasterEncryptionKey = $true
			MasterEncryptionKeyPassword = "xxxxxxyyyyz"
			
			BackupSuchAndSuchCertificate = @{  # 0 - N certs go here - where each entry is the NAME of the cert to deploy... 
				CertXyzPath = "so on"
				XyzOtherDetail	= "blah"
				BackupPathToShoveTheTHingIntoAfterCreation = "etc"
			}
			
			TDECertificateOrAnotherCertificateHere = @{
				InfoHereToCreateFromScratch = "or whatever"
			}
		}
	}
	
	DataCollectorSets  = @{
		Enabled	     = $true
		
		Consolidated = @{
			XmlDefinition		  = "convention over config - i.e., assume that 'consolidated.xml' exists in assets directory - by default - otherwise, if something's here... we use that instead."
			EnableStartWithOS	  = $true
			DaysWorthOfLogsToKeep = "nDays" # if empty then ... keep them all (no cleanup)
		}
		
		#		AnyOtherSetHere = @{
		#			
		#		}
	}
	
	ExtendedEvents	   = @{
		DisableTelemetry = $true
		
	}
	
	SqlServerManagementStudio = @{
		InstallSsms	       	= $true
		Binary			   	= "SSMS-Setup-ENU_18.9.1"
		InstallPath			= "D:\SSMS\NonDefaultPathHere"
		IncludeAzureStudio 	= $false
	}
	
	ResourceGovernor   = @{
		SomeValue    = "here"
		AnotherValue = 27
		# enabled or not... 
		# pools to create and so on... 
		# and ... assignments per pool would probably be helpful too. 
	}
	
	ClusterConfiguration = @{
		ClusterAction = "NONE" # Options: NONE, NEW, JOIN, REMOVE (as in, remove-self... )
		ClusterName   = "AWS2-CLUSTER-SQLX"
		ClusterNodes  = @(
			"AWS-SQL-1A"
			"AWS-SQL-1B"
		)
		
		ClusterIPs    = @(
			"10.10.31.120"
			"10.20.31.120"
		)
		
		Witness	      = @{
			FileShareWitness = "\\aws2-dc\clusters\"
		}
		
	}
	
	AvailabilityGroups = @{
		
		MirroringEndpoint = @{
			Enabled						    = $true
			PortNumber					    = 5022
			Name						    = "Mirroring Endpoint or whatever"
			AllowedOwnersConnectingAccounts = @(
				"xyzAdmin"
				"SQL-SomethingAccount-FromOtherBox"
			)
		}
		
		Synchronization   = @{
			AdminDbStuffHere = @{
				AddPartners = "names of partners here? though... that's odd cuz I've got replicas down below... "
				SyncCheckJobs = "add those here too... but, that's a problem as well - cuz is it all 'Partners only'?"
				
				AddFailoverProcessing = "Same kind of problem - but not as bad."
				
				AddDisabledJobCategory = "yeah, probably..."
			}
		}
		
		AgNameHere = @{
			Action = "CREATE"   # CREATE, JOIN, VERIFY?			
			
			Replicas = @(
				"AWS-SQL-1A"
				"AWS-SQL-1B" # though... need to figure out how this all works out if/when/once we're installed and such - i.e., what if SQL-1B is still being configured? 
			)
			
			Also = "NeedSomeSort of Mechanism that defines the AG db-sync-addition mechanism - log-ship/S4 'native' or ... auto-seed? or ? "
			Databases = @(
				"DbNameHere"
				"AndAnotherDbNameHere"
				"arguably, each database could be a @{} with name, seed-type, and some other details as well... "
			)
			
			Listener  = @{
				Name	   = "xxxx"
				PortNumber = 1433
				IPs	       = @(
					"10.10.30.105"
					"10.20.30.105"
				)
				
				ReadOnlyRounting   = @(
					"Todo"
				)
			}			
		}
		
		AnotherAgHere	  = @{
			x = "More Values go here as needed"
		}
	}}