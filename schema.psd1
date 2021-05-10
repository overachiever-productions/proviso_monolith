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
		AdManagementFeaturesforPowershell6PlusRequired = $false
		
		NetFx35SxsRootPath = "\\storage\Lab\resources\binaries\net3.5_sxs"
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
		
		SqlExePath		     = "\\storage\lab\resources\binaries\SqlServer\sqlserver_2019_dev\setup.exe"
		SqlInstallConfigPath = "\\storage\lab\resources\scripts\definitions\2019_xxx.ini"
		StrictInstallOnly    = $true  
		
		ServiceAccounts	     = @{
			SqlServiceAccountName	   = "xyz or group managed service account here"
			SqlServiceAccountPassword = "probably safe-ish to store this here... but, better off to have an option to run lookups and some nomenclature/specification on how to grab that"
			AgentServiceAccountName = "optional. if not present, defaults to ServiceAccountName"
			AgentServiceAccountPassword = "OPTIONAL. as with ServiceAccountPassword, can be empty if/when service-accounts are NT SERVICE\xxx accounts... "
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
		
		LimitSqlServerTls1dot2Only = $true0
		GenerateSPN			       = $true # vNEXT - see PRO-43
		DisableSaLogin			   = $false # vNEXT: Explicit option to disable sa login for PCI/HIPAA and other highly-secured environments.
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
		
		Deploy					   = $true
		
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
			
		}
		
		BackupJobs				   = @{
			Enabled					    = $true
			DatabasesToBackup		    = "{USER}"
			#Priorities = ""
			FullUserBackupsStartingTime = "02:00:00"
			# xyz and so on... 
			XyzRetention			    = "x days"
			CopyToPath				    = "etc"
			OffSitePath				    = "etc"
			OverwriteExistingJobs	    = $true
		}
		
		RestoreTestJobs		       = @{
			Enabled				      = $true
			DatabasesToRestore	      = "{USER}"
			#Priorities = "x3"
			RestoredDbNamePattern	  = "{0}_s4test"
			DropDatabasesAfterRestore = $true
			MaxNumberOfFailedDrops    = 3
			OverWriteExistingJobs	  = $true
		}
	}
	
	SqlServerManagementStudio = @{
		InstallSsms	       = $true
		BinaryPath		   = "\\storage\Lab\resources\binaries\SqlServer\SSMS-Setup-ENU_18.9.1.exe"
		IncludeAzureStudio = $false
	}
	
	_ResourceGovernor	  = @{
		# enabled or not... 
		# pools to create and so on... 
		# and ... assignments per pool would probably be helpful too. 
	}
	
	_DataCollectorSets	  			= @{
		Consolidated = @{
			definition = "path to consolidated"
			autostart  = $true
			cleanup    = nDays
		}
		
		AnyOtherSetHere	      		= @{
			etc			= "path here"
		}
	}
	
	ClusterConfiguration = @{
		ClusterAction    = "NONE" # Options: NONE, NEW, JOIN, REMOVE (as in, remove-self... )
		ClusterName	     = "AWS2-CLUSTER-SQLX"
		ClusterNodes	 = @(
			"AWS-SQL-1A"
			"AWS-SQL-1B"
		)
		
		ClusterIPs	     = @(
			"10.10.31.120"
			"10.20.31.120"
		)
		
		FileShareWitness = "\\aws2-dc\clusters\"
	}
	
	_AvailabilityGroups = @{
		AGAction		  = "CREATE" # options: NONE, CREATE, JOIN
		AGName		      = "xxxx"
		
		Replicas		  = @(
			"AWS-SQL-1A"
			"AWS-SQL-1B" # though... need to figure out how this all works out if/when/once we're installed and such - i.e., what if SQL-1B is still being configured? 
		)
		
		MirroringEndpoint = @{
			Enabled						    = $true
			PortNumber					    = 5022
			Name						    = "Mirroring Endpoint or whatever"
			AllowedOwnersConnectingAccounts = @(
				"xyzAdmin"
				"SQL-SomethingAccount-FromOtherBox"
			)
		}
		
		AGListener	      = @{
			AGListenerName	   = "xxxx"
			ListenerPortNumber = 1433
			ListenerIPs	       = @(
				"10.10.30.105"
				"10.20.30.105"
			)
			
			ReadOnlyRounting   = @(
				"Todo"
			)
		}
	}
}