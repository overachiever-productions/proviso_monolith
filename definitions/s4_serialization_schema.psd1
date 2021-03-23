<#
	Notes and such here... 

#>

@{
	
	TargetServer = "AWS-SQL-1A"
	LimitHostTls1dot2Only = $true
	
	HostName	 = @{
		DomainName  = "aws.local"
		MachineName = "AWS-SQL-1A"
	}
	
	Preferences = @{
		DvdDriveToZ				     = $true
		OptimizeExplorer			 = $true
		DisableServerManagerOnLaunch = $true
		SetPowerConfigHigh		     = $true
		EnableDiskPerfCounters	     = $true
	}
	
	RequiredPackages = @{
		NetFxForPre2016InstancesRequired = $false
		AdManagementFeaturesforPowershell6PlusRequired = $false
	}
	
	NetworkDefinitions = @{
		
		# allows N different adapters. 
		AdapterX = @{
			ProvisioningPriority    = 1
			
			# TODO: figure out schema to enable/allow multiple addresses - i.e., I'll need the following 3-4 options... but up to N times... 
			IpAddress  = "10.10.30.101/16"
			Gateway    = "10.10.0.1"
			PrimaryDns = "192.168.1.1"
			SecondaryDns = "208.67.222.222"
		}
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
	
	ClusterConfiguration = @{
		ClusterAction		  = "NONE" # Options: NONE, PRE-NEW, PRE-JOIN, POST-NEW, POST-JOIN (where PRE = before SQL install, and POST = after SQL install.)
		ClusterName		      = "AWS-CLUSTER-1"
		ClusterNodes		  = @(
			"AWS-SQL-1A"
			"AWS-SQL-1B"
		)
		
		ClusterIPs		      = @(
			"10.10.30.102"
			"10.20.30.102"
		)
		
		FileShareWitness = "\\aws-dc\"
	}
	
	FirewallRules = @{
		EnableFirewallForSqlServer = $true;
		EnableFirewallForSqlServerDAC = $true;
		EnableFirewallForSqlServerMirroring = $true;
	}
	
	SqlServerInstallation = @{
		
		SqlExePath		     = "\\storage\Lab\binaries\SqlServer\sqlserver_2019_dev\setup.exe"
		SqlInstallConfigPath = "//storage.overachiever.net/lab/scripts/definitions/2019_xxx.ini"
		
		ServiceAccount	     = @{
			ServiceAccountName	   = "xyz or group managed service account here"
			ServiceAccountPassword = "probably safe-ish to store this here... but, better off to have an option to run lookups and some nomenclature/specification on how to grab that"
		}
		
		SecuritySetup	     = @{
			EnableSqlAuth			    = $true
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
		
		EnabledUserRights		   = @{
			LockPagesInMemory			  = $true
			PerformVolumeMaintenanceTasks = $true
		}
		
		DisableSaLogin			   = $false  # probably want to flesh-this 'option' out a bit more - i.e., might be other options to specify here. 
		
		TraceFlags				   = @(
			3226
			7745
			7752
		)
	}
	
	AdminDb = @{
		
		Deploy					   = $true
		SourcePath				   = "uri here - and if it's web... try to download, otherwise, just grab the file from local path or UNC"
		
		EnableAdvancedCapabilities = $true
		
		ConfigureInstance		   = @{
			MAXDOP					    = 2
			MaxServerMemoryGBs		    = 502
			CostThresholdForParallelism = 40
		}
		
		DatabaseMail			   = @{
			Enabled					    = $true
			OperatorEmail			    = "mike@overachiever.net"
			SmtpAccountName			    = "AWS - East"
			SmtpOutgoingEmailAddress    = "alerts@overachiever.net"
			SmtpServerName			    = "email-smtp.us-east-1.amazonaws.com"
			SmtpPortNumber			    = 587
			SmtpRequiresSSL			    = $true
			SmptUserName			    = "AKIAI2QUP43VN5VRF73Q"
			SmtpPassword			    = "AkbYdzRcUiM1BqsqcCLbRi3fgE7pvRXxxxxxxxHAr6KKE"
			SendTestEmailUponCompletion = $true
		}
		
		ServerHistoryManagement    = @{
			Enabled			      = $true
			SqlServerLogsToKeep   = 12
			EmailHistoryRetention = "6 months"
			xyzHistoryRetention   = "2 months"
		}
		
		EnableDiskMonitoring	   = @{
			Enabled			       = $true
			WarnWhenFreeGBsGoBelow = "32"
		}
		
		SqlServerAlerts		       = @{
			IOAlertsEnabled	       = $true
			IOAlertsFiltered	   = $false # for example... 
			SeverityAlertsEnabled  = $true
			SeverityAlertsFiltered = $true
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
		
		AvailabilityGroups		   = @{
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
	
	ResourceGovernor	  = @{
		# enabled or not... 
		# pools to create and so on... 
		# and ... assignments per pool would probably be helpful too. 
	}
	
	DataCollectorSets	  			= @{
		Consolidated = @{
			definition = "path to consolidated"
			autostart  = $true
			cleanup    = nDays
		}
		
		AnyOtherSetHere	      		= @{
			etc			= "path here"
		}
	}
}