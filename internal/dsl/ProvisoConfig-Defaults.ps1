﻿Set-StrictMode -Version 1.0;

# NOTE: $script:be8c742fDefaultConfigData is assigned at the BOTTOM of this script... 

[hashtable]$script:ProvisoConfigDefaults = [hashtable]@{
	
	Host = @{
		TargetServer	    = "{~DEFAULT_PROHIBITED~}"
		TargetDomain	    = "{~DEFAULT_PROHIBITED~}"
		
		AllowGlobalDefaults = $true
		
		NetworkDefinitions  = @{
			"{~ANY~}" = @{
				ProvisioningPriority = 5
				InterfaceAlias	     = "{~PARENT~}"
				
				AssumableIfNames	 = @(
					"{~DEFAULT_PROHIBITED~}"
				)
				
				IpAddress		     = "{~DEFAULT_PROHIBITED~}"
				Gateway			     = "{~DEFAULT_PROHIBITED~}"
				PrimaryDns		     = "{~DEFAULT_PROHIBITED~}"
				SecondaryDns		 = "{~DEFAULT_PROHIBITED~}"
			}
		}
		
		LocalAdministrators = @("{~EMPTY~}")
		
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
				VolumeName			    = "{~DEFAULT_PROHIBITED~}"
				VolumeLabel		     	= "{~PARENT~}"
				
				PhysicalDiskIdentifiers = @{
					DiskNumber 		= "{~DEFAULT_IGNORED~}"
					VolumeId		= "{~DEFAULT_IGNORED~}"
					ScsiMapping		= "{~DEFAULT_IGNORED~}"
					DeviceId    	= "{~DEFAULT_IGNORED~}"
					RawSize    		= "{~DEFAULT_IGNORED~}"
				}
			}
		}
	}
	
	ExpectedDirectories = @{
		"{~SQLINSTANCE~}" = @{
			VirtualSqlServerServiceAccessibleDirectories = @("{~EMPTY~}")
			RawDirectories = @("{~EMPTY~}")
		}
	}
	
	ExpectedShares = @{
		"{~ANY~}" = @{
			ShareName	   		= "{~PARENT~}"
			SourceDirectory 	= "{~DEFAULT_PROHIBITED~}"
			ReadOnlyAccess 		= @("{~EMPTY~}")
			ReadWriteAccess 	= @("{~EMPTY~}")
		}
	}
	
	SqlServerInstallation = @{
		"{~SQLINSTANCE~}" = @{
			SqlExePath	      = "{~DEFAULT_PROHIBITED~}"
			StrictInstallOnly = $true
			
			Setup			  = @{
				Version				      = "{~EMPTY~}"
				Edition				      = "{~EMPTY~}"
				
				Features				  = "{~DEFAULT_PROHIBITED~}"
				Collation				  = "SQL_Latin1_General_CP1_CI_AS"
				InstantFileInit		      = $true
				
				InstallDirectory		  = "{~DYNAMIC~}"
				InstallSharedDirectory    = "{~DYNAMIC~}"
				InstallSharedWowDirectory = "{~DYNAMIC~}"
				
				SqlTempDbFileCount	      = "{~DYNAMIC~}" # 4 or .5 * core-count (whichever is larger)
				SqlTempDbFileSize		  = 1024
				SqlTempDbFileGrowth	      = 256
				SqlTempDbLogFileSize	  = 2048
				SqlTempDbLogFileGrowth    = 256
				
				FileStreamLevel		      = 0
				
				NamedPipesEnabled		  = $false
				TcpEnabled			      = $true
				
				LicenseKey			      = "{~EMPTY~}"
			}
			
			ServiceAccounts   = @{
				SqlServiceAccountName	    = "{~DYNAMIC~}"
				SqlServiceAccountPassword   = "{~EMPTY~}"
				AgentServiceAccountName	    = "{~DYNAMIC~}"
				AgentServiceAccountPassword = "{~EMPTY~}"
				FullTextServiceAccount	    = "{~DYNAMIC~}"
				FullTextServicePassword	    = "{~EMPTY~}"
			}
			
			SqlServerDefaultDirectories = @{
				InstallSqlDataDir = "{~DYNAMIC~}"
				SqlDataPath	      = "{~DYNAMIC~}"
				SqlLogsPath	      = "{~DYNAMIC~}"
				SqlBackupsPath    = "{~DYNAMIC~}"
				TempDbPath	      = "{~DYNAMIC~}"
				TempDbLogsPath    = "{~DYNAMIC~}"
			}
			
			SecuritySetup	  = @{
				EnableSqlAuth		  = $false
				AddCurrentUserAsAdmin = $false
				SaPassword		      = "{~DEFAULT_PROHIBITED~}"
				MembersOfSysAdmin	  = @("{~EMPTY~}")
			}
		}
	}
	
	SqlServerConfiguration = @{
		"{~SQLINSTANCE~}" = @{
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
		"{~SQLINSTANCE~}" = @{
			# TODO: add any keys here to ProvisoConfig.ps1 -> Is-KeyValid and other implementations... 
			
			# some kind of base path? or an option to override proviso-root configs... 
			# then an SP key/entry/option
			# and a CU key/entry/option
		}
	}
	
	AdminDb = @{
		"{~SQLINSTANCE~}" = @{
			
			Deploy		     	= $false
			OverrideSource		= "{~EMPTY~}"
			
			InstanceSettings = @{
				Enabled					    = $false # too much of a custom concern to enable by DEFAULT. 
				MAXDOP					    = 2
				MaxServerMemoryGBs			= "{~EMPTY~}"
				CostThresholdForParallelism = 40
				OptimizeForAdHocQueries	    = $true
			}
			
			DatabaseMail	 = @{
				Enabled					    = $true
				OperatorEmail			    = "{~DEFAULT_PROHIBITED~}"
				SmtpAccountName			    = "{~DEFAULT_PROHIBITED~}"
				SmtpOutgoingEmailAddress    = "{~DEFAULT_PROHIBITED~}"
				SmtpServerName			    = "{~DEFAULT_PROHIBITED~}"
				SmtpPortNumber			    = "{~DEFAULT_PROHIBITED~}"
				SmtpRequiresSSL			    = $true
				SmtpAuthType			    = "{~DEFAULT_PROHIBITED~}"
				SmptUserName			    = "{~DEFAULT_PROHIBITED~}"
				SmtpPassword			    = "{~DEFAULT_PROHIBITED~}"
				SendTestEmailUponCompletion = $true
			}
			
			HistoryManagement = @{
				Enabled				     	= $true
				JobName						= "Regular History Cleanup"
				SqlServerLogsToKeep	     	= 18
				AgentJobHistoryRetention 	= "6 weeks"
				BackupHistoryRetention   	= "6 weeks"
				EmailHistoryRetention    	= "6 months"
				OverWriteExistingJobs    	= $false
			}
			
			DiskMonitoring   = @{
				Enabled			       	= $true
				JobName					= "Regular Drive Space Checks"
				WarnWhenFreeGBsGoBelow 	= "32"
				OverWriteExistingJobs  	= $false
			}
			
			Alerts		     = @{
				IOAlertsEnabled	       = $true
				IOAlertsFiltered	   = $false
				SeverityAlertsEnabled  = $true
				SeverityAlertsFiltered = $true
				# Hmmm... add a job name for the filter? 
			}
			
			IndexMaintenance = @{
				Enabled				    = $false
				JobsNamePrefix		    = "Index Maintenance - "
				DailyJobRunsOnDays	    = "M,W,F"
				WeekendJobRunsOnDays    = "Su"
				StartTime			    = "21:50:00"
				TimeZoneForUtcOffset    = "" # vNEXT, make this one {~DYNAMIC~} 
				JobsCategoryName	    = "Database Maintenance"
				OperatorToAlertOnErrors = "Alerts"
				OverWriteExistingJobs   = $false
			}
			
			ConsistencyChecks = @{
				Enabled					     = $false
				JobName					     = "Database Consistency Checks"
				ExecutionDays			     = "M,W,F,Su"
				StartTime				     = "04:10:00"
				Targets					     = "{USER}"
				Exclusions				     = "{~EMPTY~}"
				Priorities				     = "{~EMPTY~}"
				IncludeExtendedLogicalChecks = $false
				TimeZoneForUtcOffset		 = "{~EMPTY~}" # vNEXT, make this one {~DYNAMIC~} 
				JobCategoryName			     = "Database Maintenance"
				Operator					 = "Alerts"
				Profile					     = "General"
				JobEmailPrefix			     = "[Database Corruption Checks] - "
				OverWriteExistingJobs	     = $false
			}
			
			BackupJobs	     = @{
				Enabled					    = $true
				JobsNamePrefix			    = "Database Backups - "
				
				UserDatabasesToBackup	    = "{USER}"
				UserDbsToExclude		    = "{~EMPTY~}"
				CertificateName			    = "{~EMPTY~}"
				BackupDirectory			    = "{DEFAULT}"
				CopyToDirectory			    = "{~EMPTY~}"
				SystemBackupRetention	    = "4 days"
				CopyToSystemBackupRetention = "4 days" # todo, have this default to whatever is set for SystemBackupRetention - i.e., if they set that to 5 days, this is 5 days... 
				UserBackupRetention		    = "3 days"
				CopyToUserBackupRetention   = "3 days" # ditto. and, of course, none of these 'matter' unless there's a CopyToDirectory specified
				LogBackupRetention		    = "73 hours"
				CopyToLogBackupRetention    = "73 hours" # ditto
				AllowForSecondaries		    = $false
				SystemBackupsStart		    = "18:50:00"
				UserBackupsStart		    = "02:00:00"
				DiffBackupsStart		    = "{~EMPTY~}"
				DiffBackupsEvery		    = "{~EMPTY~}"
				LogBackupsStart			    = "00:02:00"
				LogBackupsEvery			    = "10 minutes"
				TimeZoneForUtcOffset	    = "{~EMPTY~}"
				JobsCategoryName		    = "Backups"
				Operator				    = "Alerts"
				Profile					    = "General"
				OverWriteExistingJobs	    = $false
			}
			
			RestoreTestJobs  = @{
				Enabled			      		= $false
				JobName			      		= "Database Backups - Regular Restore Tests"
				JobStartTime		  		= "22:30:00"
				TimeZoneForUtcOffset  		= "{~EMPTY~}"
				JobCategoryName	      		= "Backups"
				AllowForSecondaries   		= $false
				DatabasesToRestore    		= "{READ_FROM_FILESYSTEM}"
				DatabasesToExclude    		= "{~EMPTY~}"
				Priorities		      		= "{~EMPTY~}"
				BackupsRootPath	      		= "{DEFAULT}"
				RestoreDataPath	      		= "{DEFAULT}"
				RestoreLogsPath	      		= "{DEFAULT}"
				RestoredDbNamePattern 		= "{0}_s4test"
				AllowReplace		  		= "{~DEFAULT_PROHIBITED~}"
				RpoThreshold		  		= "24 hours"
				DropDatabasesAfterRestore   = $true
				MaxNumberOfFailedDrops 		= 3
				Operator			  		= "Alerts"
				Profile			      		= "General"
				JobEmailPrefix		      	= "[RESTORE TEST] - "
				OverWriteExistingJobs 		= $false
			}
		}
	}
	
	#region Encryption Keys
# TODO: determine if this needs to be part of the admindb - think it does. NOT cuz it 'does', but because I don't want to bother 
# 		trying to create certs and stuff WITHOUT the admindb... 
#	SqlEncryptionKeys = @{
#		"{~SQLINSTANCE~}" = @{
#			CreateMasterEncryptionKey    = $true
#			MasterEncryptionKeyPassword  = "" # allow this to be empty/blank (i.e., create something dynamic)
#			
#			BackupSuchAndSuchCertificate = @{
#				#					# 0 - N certs go here - where each entry is the NAME of the cert to deploy... 
#				#					CertXyzPath							       = "so on"
#				#					XyzOtherDetail							   = "blah"
#				#					BackupPathToShoveTheTHingIntoAfterCreation = "etc"
#			}
#			
#			TDECertificateOrAnotherCertificateHere = @{
#				#					InfoHereToCreateFromScratch = "or whatever"
#			}
#		}
#	}
	#endregion 
	
	DataCollectorSets = @{
		"{~ANY~}" = @{
			Enabled			      = $false
			XmlDefinition		  = "{~DYNAMIC~}"
			EnableStartWithOS	  = $false
			DaysWorthOfLogsToKeep = 90
		}
	}
	
	ExtendedEvents = @{
		"{~SQLINSTANCE~}" = @{
			DisableTelemetry = $true
			"{~ANY~}"	     = @{
				Enabled 		= $true  # if we're going to define it, it'll default to true
				SessionName		= "{~PARENT~}"
				
				# TODO: add these params to Is-NonValidChildKey
				DefinitionPathOrWhateverElseWeWouldUseHere = "somethingName" # which'd be a .sql file found at: \assets\xetraces\<name>.sql or whatever.
				#StartWithSystem	# or is this part of the definition?
				#EnabledAtCreation  # or is this part of the definition?
			}
		}
	}
	
	SqlServerManagementStudio = @{
		InstallSsms	       	= $false
		Binary 			 	= "{~DEFAULT_PROHIBITED~}"
		IncludeAzureStudio 	= $false
		InstallPath	       	= "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18"
	}
	
	ResourceGovernor = @{
		"{~SQLINSTANCE~}" = @{
			Enabled = $false # default to off by default. 
			
			# actually, might need ... thingies AND pools? i.e., might need 2x different collections of thingies - which could have ~ANY~ names... 
			
			"{~ANY~}" = @{
				
				PoolNameOrWhatever = "{~PARENT~}"
			}
		}
	}
	
	ClusterConfiguration = @{
		ClusterType = "NONE"
	}
	
	AvailabilityGroups = @{
		"{~SQLINSTANCE~}" = @{
			EnabledOrStrictEnabled = "probably need 2x keys/entries here... but idea is a) configure AG membership or not? and b) what if ... we find the server as PART of an AG that's NOT defined below?"
			
			MirroringEndpoint	   = @{
				Enabled						    = $false
				PortNumber					    = 5022
				Name						    = ""
				AllowedOwnersConnectingAccounts = @("{~EMPTY~}")
			}
			
			SynchronizationChecks  = @{
				AdminDbStuffHere = @{
					AddPartners		       = ""
					SyncCheckJobs		   = ""
					AddFailoverProcessing  = ""
					AddDisabledJobCategory = ""
				}
			}
			
			# TODO: need to create a wrapper here for ... AGs ... which is odd/problematic because that's what I already called the parent wrapper for ALL ag stuff. 
			# 		but... point is, this needs to be modeled similar to expected disks/nics - where there's a 'wrapper'/key to pull from ... 
			"{~ANY~}"			   = @{
				Action   = "NONE"
				
				Replicas = @("{~EMPTY~}")
				
				Seeding  = @{
					
				}
				
				Databases = @("{~EMPTY~}")
				
				Listener = @{
					Name			    = "{~DEFAULT_PROHIBITED~}"
					PortNumber		    = 1433
					IPs				    = @("{~EMPTY~}")
					
					ReadOnlyRounting    = @("{~EMPTY~}")
					
					GenerateClusterSPNs = $false
				}
			}
		}
	}
	
	CustomSqlScripts = @{   # or, call this just 'SqlScripts'?
		"{~SQLINSTANCE~}" = @{
			Deploy = $false
			
			# _MAY_ end up configuring this (behind the scenes) so that there's a single, default, script group - similar to MSSQLSERVER for sql instances..
			# 		or, that MAY end up being too much of a pain and i may require explicit groups... 
			ScriptGroups = @{
				"{~ANY~}" = @{
#					whateverGoesHere
#					ProbablyADirectory
#					ThenAListOrArrayOfScriptNames
#					Or
#					MaybeADirective
#					Like
#					ReadAll
#					etc
				}
			}
		}
	}
}

$script:be8c742fDefaultConfigData = $script:ProvisoConfigDefaults;