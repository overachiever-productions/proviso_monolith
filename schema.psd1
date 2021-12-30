@{
	# NOTE: This is the DSL/New Schema
	Host = @{
		Compute = @{
			CoreCount	  	 = 2
			NumaNodes		 = 1
			RamGBs	 		 = 8
			TargetOS  		 = "Windows Server 2019"
			SystemVolumeSize = "80GB"
		}
		
		TargetServer	   = "AWS-SQL-1A"
		TargetDomain	   = ""
		
		LocalAdministrators = @(
			"OVERACHIEVER\dev-ops"
		)
		
		NetworkDefinitions = @{
			
			VMNetwork = @{
				ProvisioningPriority = 1
				
				AssumableIfNames	 = @(
					"Ethernet0"
					"Ethernet1"
				)
				InterfaceAlias	     = "VM Network"
				
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
			DisableMonitorTimeout	     = $true
			EnableDiskPerfCounters	     = $true
		}
		
		RequiredPackages   = @{
			WsfcComponents				     = $true
			
			NetFxForPre2016InstancesRequired = $false
			AdManagementFeaturesforPowershell6PlusRequired = $false # not 100% sure this is still in use... 
		}
		
		LimitHostTls1dot2Only = $true
		
		FirewallRules	   = @{
			EnableFirewallForSqlServer		    = $true
			EnableFirewallForSqlServerDAC	    = $true
			EnableFirewallForSqlServerMirroring = $true
			
			EnableICMP						    = $true
		}
		
		ExpectedDisks	   = @{
			
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
					VolumeId   = "000000001532"
				}
			}
		}
	}
	
	ExpectedDirectories = @{
		
		MSSQLSERVER = @{
			
			VirtualSqlServerServiceAccessibleDirectories = @(
				"D:\SQLData"
				"D:\Traces"
				"E:\SQLBackups"
				"F:\SQLTempDB"
				"F:\Traces"
			)
			
			RawDirectories							     = @(
				"D:\SampleDirectory"
				"E:\Archived"
			)
		}
	}
	
	ExpectedShares = @{
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
		
		MSSQLSERVER = @{
			SqlExePath	      = "sqlserver_2019_dev"
			SqlIniFile	      = "2019_STANDARD_INSTALL"
			StrictInstallOnly = $true
			
			ServiceAccounts   = @{
				SqlServiceAccountName	    = "xyz or group managed service account here"
				SqlServiceAccountPassword   = "probably safe-ish to store this here... but, better off to have an option to run lookups and some nomenclature/specification on how to grab that"
				AgentServiceAccountName	    = "optional. if not present, defaults to ServiceAccountName"
				AgentServiceAccountPassword = "OPTIONAL. as with ServiceAccountPassword, can be empty if/when service-accounts are NT SERVICE\xxx accounts... "
			}
			
			SecuritySetup	  = @{
				EnableSqlAuth			    = $true
				AddCurrentUserAsAdmin	    = $false
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
			
			LicenseKey	      = ""
		}
	}
	
	SqlServerConfiguration = @{
		
		MSSQLSERVER = @{
			LimitSqlServerTls1dot2Only = $true
			GenerateSPN			       = $true 
			DisableSaLogin			   = $false
			DeployContingencySpace	   = $true;
			
			EnabledUserRights		   = @{
				LockPagesInMemory			  = $true
				PerformVolumeMaintenanceTasks = $true
			}
			
			TraceFlags = @(
				3226
				7745
				7752
			)
		}
	}
	
	SqlServerPatches   = @{
		
		MSSQLSERVER = @{
			SuchAndSuchSP = "for older versions SPs might make sense. Just put a path here..."
			SuchAndSuchCU = "path here for CUxxx"
		}
	}
	
	AdminDb = @{
		
		MSSQLSERVER = @{
			Deploy		      = $true
			#OverrideSource    = "assets/admindb_latest.sql"
			
			InstanceSettings = @{
				Enabled 					= $true
				MAXDOP					    = 2
				MaxServerMemoryGBs		    = 502
				CostThresholdForParallelism = 40
				OptimizeForAdHocQueries	    = $true # Default is TRUE - i.e., only way this'll be false is if there's a config entry that explicitly sets to $false
			}
			
			DatabaseMail	  = @{
				Enabled					    = $true
				OperatorEmail			    = "mike@overachiever.net"
				SmtpAccountName			    = "AWS - East"
				SmtpOutgoingEmailAddress    = "alerts@overachiever.net"
				SmtpServerName			    = "email-smtp.us-east-1.amazonaws.com"
				SmtpPortNumber			    = 587
				SmtpRequiresSSL			    = $true
				SmtpAuthType			    = "BASIC" # OPTIONS: { BASIC | WINDOWS | ANONYMOUS } - defaults to BASIC
				SmptUserName			    = "AKIAI2QUP43VN5VRF73Q"
				SmtpPassword			    = "AkbYdzRcUiM1BqsqcCLbRi3fgE7pvRXxxxxxxxHAr6KKE"
				SendTestEmailUponCompletion = $true
			}
			
			HistoryManagement = @{
				Enabled				     = $true
				SqlServerLogsToKeep	     = 18
				AgentJobHistoryRetention = "6 weeks"
				BackupHistoryRetention   = "6 weeks"
				EmailHistoryRetention    = "6 months"
			}
			
			DiskMonitoring    = @{
				Enabled			       = $true
				WarnWhenFreeGBsGoBelow = "32"
			}
			
			Alerts		      = @{
				IOAlertsEnabled	       = $true
				IOAlertsFiltered	   = $false 
				SeverityAlertsEnabled  = $true
				SeverityAlertsFiltered = $true
			}
			
			IndexMaintenance  = @{
				Enabled				    = $true
				DailyJobRunsOnDays	    = "M,W,F"
				WeekendJobRunsOnDays    = "Su"
				StartTime			    = "22:30:00"
				TimeZoneForUtcOffset    = "Central Standard Time"
				JobsNamePrefix		    = "Index Maintenance"
				JobsCategoryName	    = "Database Maintenance"
				OperatorToAlertOnErrors = "Alerts"
			}
			
			ConsistencyChecks = @{
				Enabled					     = $true
				ExecutionDays			     = "M, W, F, Su"
				StartTime				     = "04:10:00"
				Targets					     = "{USER}"
				IncludeExtendedLogicalChecks = $false
				Exclusions				     = ""
				Priorities				     = ""
				TimeZoneForUtcOffset		 = "Central Standard Time"
				JobName					     = "Database Consistency Checks"
				JobCategoryName			     = "Database Maintenance"
				Operator					 = "Alerts"
				JobEmailPrefix			     = "[Database Corruption Checks] "
				Profile					     = "General"
			}
			
			BackupJobs	      = @{
				Enabled					    = $true
				UserDatabasesToBackup	    = "{USER}"
				UserDbsToExclude		    = ""
				CertificateName			    = ""
				BackupDirectory			    = "{DEFAULT}"
				CopyToDirectory			    = ""
				SystemBackupRetention	    = "4 days"
				CopyToSystemBackupRetention = ""
				UserBackupRetention		    = "3 days"
				CopyToUserBackupRetention   = ""
				LogBackupRetention		    = "73 hours"
				CopyToLogBackupRetention    = ""
				AllowForSecondaries		    = $false
				SystemBackupsStart		    = "18:50:00"
				UserBackupsStart		    = "02:00:00"
				LogBackupsStart			    = "00:02:00"
				LogBackupsEvery			    = "10 minutes"
				DiffBackupsStart		    = ""
				DiffBackupsEvery		    = ""
				TimeZoneForUtcOffset	    = ""
				JobsNamePrefix			    = "Database Backups - "
				JobsCategoryName		    = "Backups"
				Operator				    = "Alerts"
				Profile					    = "General"
			}
			
			RestoreTestJobs   = @{
				Enabled			      = $true
				JobName			      = "Database Backups - Regular Restore Tests"
				JobStartTime		  = "22:30:00"
				TimeZoneForUtcOffset  = ""
				JobCategoryName	      = "Backups"
				AllowForSecondaries   = $false
				DatabasesToRestore    = "{READ_FROM_FILESYSTEM}"
				DatabasesToExclude    = ""
				Priorities		      = ""
				BackupsRootPath	      = "{DEFAULT}"
				RestoreDataPath	      = "{DEFAULT}"
				RestoreLogsPath	      = "{DEFAULT}"
				RestoredDbNamePattern = "{0}_s4test"
				AllowReplace		  = ""
				RpoThreshold		  = "24 hours"
				DropDbsAfterRestore   = $true
				MaxFailedDrops	      = 3
				Operator			  = "Alerts"
				Profile			      = "General"
				JobEmailPrefix	      = "[RESTORE TEST] "
			}
			
			SqlEncryptionKeys = @{
				
				CreateMasterEncryptionKey    = $true
				MasterEncryptionKeyPassword  = "xxxxxxyyyyz"
				
				BackupSuchAndSuchCertificate = @{
					# 0 - N certs go here - where each entry is the NAME of the cert to deploy... 
					CertXyzPath							       = "so on"
					XyzOtherDetail							   = "blah"
					BackupPathToShoveTheTHingIntoAfterCreation = "etc"
				}
				
				TDECertificateOrAnotherCertificateHere = @{
					InfoHereToCreateFromScratch = "or whatever"
				}
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
		
		#AnotherCollectorSetHere = @{
		#			
		#		}
	}
	
	ExtendedEvents = @{
		
		MSSQLSERVER = @{
			
			DisableTelemetry = $true
			
			#		SuchAndSuchXE    = @{
			#			Enabled = $true
			#			Definition = "path??+ filename to the T-SQL definition. Arguably, I GUESS I could put the definition in here as T-SQL as well
			#right? 
			#it'd just wrap
			#around and such."
			#		}
		}
	}
	
	SqlServerManagementStudio = @{
		InstallSsms	       	= $true
		Binary			   	= "SSMS-Setup-ENU_18.9.1"
		InstallPath			= "D:\SSMS\NonDefaultPathHere"
		IncludeAzureStudio 	= $false
	}
	
	ResourceGovernor = @{
		
		MSSQLSERVER = @{
			SomeValue    = "here"
			AnotherValue = 27
			# enabled or not... 
			# pools to create and so on... 
			# and ... assignments per pool would probably be helpful too. 
		}
	}
	
	ClusterConfiguration = @{
		ClusterType		 = "NONE" # Options: AG, AGx (scale-out/workgroup/etc.), FCI, NONE
		EvictionBehavior = "NOTHING | WARN | FAIL/ABORT | FORCE-EVICTION"; # what to do if current machine is PART of a cluster, but ClusterType = "NONE"
		
		ClusterName   = "AWS2-CLUSTER-SQLX"
		ClusterNodes  = @(
			"AWS-SQL-1A"
			"AWS-SQL-1B"  # will attempt to JOIN/ADD other nodes ... unless they're not present... then it will just add what's possible/available/present
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
		
		MSSQLSERVER = @{
			EnabledOrStrictEnabled = "probably need 2x keys/entries here... but idea is a) configure AG membership or not? and b) what if ... we find the server as PART of an AG that's NOT defined below?"
			
			MirroringEndpoint	   = @{
				Enabled						    = $true
				PortNumber					    = 5022
				Name						    = "Mirroring Endpoint or whatever"
				AllowedOwnersConnectingAccounts = @(
					"xyzAdmin"
					"SQL-SomethingAccount-FromOtherBox"
				)
			}
			
			SynchronizationChecks  = @{
				AdminDbStuffHere = @{
					AddPartners		       = "names of partners here? though... that's odd cuz I've got replicas down below... "
					SyncCheckJobs		   = "add those here too... but, that's a problem as well - cuz is it all 'Partners only'?"
					
					AddFailoverProcessing  = "Same kind of problem - but not as bad."
					
					AddDisabledJobCategory = "yeah, probably..."
				}
			}
			
			AgNameHere			   = @{
				Action   = "CREATE" # as with clusters, just expect it... if it doesn't exist, create it. otherwise JOIN.		
				
				Replicas = @(
					"AWS-SQL-1A"
					"AWS-SQL-1B" # though... need to figure out how this all works out if/when/once we're installed and such - i.e., what if SQL-1B is still being configured? 
				)
				
				Seeding  = @{
					Something	   = "NeedSomeSort of Mechanism that defines the AG db-sync-addition mechanism - log-ship/S4 'native' or ... auto-seed? or ? "
					PathToWhatever = "other value and so on... "
				}
				
				Databases = @(
					"DbNameHere"
					"AndAnotherDbNameHere"
					"arguably, each database could be a @{} with name, seed-type, and some other details as well... "
				)
				
				Listener = @{
					Name			    = "xxxx"
					PortNumber		    = 1433
					IPs				    = @(
						"10.10.30.105"
						"10.20.30.105"
					)
					
					ReadOnlyRounting    = @(
						"Todo"
					)
					
					GenerateClusterSPNs = $false # primary, secondary, etc. + LISTENER NODE ITSELF.
				}
			}
			
			AnotherAgHere		   = @{
				x = "More Values go here as needed"
			}
		}
	}
	
	CustomSqlScripts = @{
		
		MSSQLSERVER = @{
			XyzScriptHere  = "path??(yeah) and file-name"
			XyzScriptHere2 = "these need to be ordered"
			XyzScriptHere3 = "as in, do the first, then the second, then the third, and so on. "
		}
	}
}