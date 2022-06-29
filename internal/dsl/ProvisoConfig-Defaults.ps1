Set-StrictMode -Version 1.0;

# NOTE: $script:be8c742fDefaultConfigData is assigned at the BOTTOM of this script... 

# WARN: These are NOT 'just' defaults - they also define which keys are legit/allowed. 
# 			And, for that purpose, NO default can ever have an empty "" or $null value. Instead, use {~EMPTY~}

[hashtable]$script:ProvisoConfigDefaults = [hashtable]@{
	
	Host = @{
		TargetServer	    = "{~DEFAULT_PROHIBITED~}"
		TargetDomain	    = "{~DEFAULT_PROHIBITED~}"
		
		AllowGlobalDefaults = $true
		
		Compute			    = @{
			Enforce 				= $false		# probably need a better name here - strict or 'report' ... but this means: should we check (and alert) on these details or not? 
			CoreCount 				= "{~EMPTY~}" # allow empty ... as in... if not present, then ... take whatever we're given? 
			HyperThreadingEnabled 	= $false
			NumaNodes 				= 1 # decent enough default... i.e., anything > 1 is going to be a custom config anyhow... 
			RamGBs  				= 32 # again, i can just spam in some sort of default and ... if it's different... complain/alert.
			TargetOs 				= "{~EMPTY~}"   # yeah... ignore... unless there's a specified value.
		}
		
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
				SecondaryDns		 = "{~EMPTY~}"
			}
		}
		
		LocalAdministrators = @("{~EMPTY_ARRAY~}")
		
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
					DiskNumber 		= "{~EMPTY~}"
					VolumeId		= "{~EMPTY~}"
					ScsiMapping		= "{~EMPTY~}"
					DeviceId    	= "{~EMPTY~}"
					RawSize    		= "{~EMPTY~}"
				}
			}
		}
	}
	
	ExpectedDirectories = @{
		"{~SQLINSTANCE~}" = @{
			VirtualSqlServerServiceAccessibleDirectories = @("{~EMPTY_ARRAY~}")
			RawDirectories = @("{~EMPTY_ARRAY~}")
		}
	}
	
	ExpectedShares = @{
		"{~ANY~}" = @{
			ShareName	   		= "{~PARENT~}"
			SourceDirectory 	= "{~DEFAULT_PROHIBITED~}"
			ReadOnlyAccess 		= @("{~EMPTY_ARRAY~}")
			ReadWriteAccess 	= @("{~EMPTY_ARRAY~}")
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
				SqlServiceAccountName	    		= "{~DYNAMIC~}"
				SqlServiceAccountPassword   		= "{~EMPTY~}"
				AgentServiceAccountName	    		= "{~DYNAMIC~}"
				AgentServiceAccountPassword 		= "{~EMPTY~}"
				FullTextServiceAccountName	    	= "{~DYNAMIC~}"
				FullTextServiceAccountPassword	    = "{~EMPTY~}"
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
				MembersOfSysAdmin	  = @("{~EMPTY_ARRAY~}")
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
			TargetSP = "{~EMPTY~}"
			TargetCU = "{~EMPTY~}"
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
				WarnWhenFreeGBsGoBelow 	= 32
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
				AllowReplace		  		= "{~EMPTY~}"
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
#			BackupSuchAndSuchCertificate = @{ # 0 - N certs go here - where each entry is the NAME of the cert to deploy... 
# 				# could also be a STREAM of data here instead of file paths and stuff... 
#				# CertXyzPath							       = "so on"
#				# XyzOtherDetail							   = "blah"
#				# BackupPathToShoveTheTHingIntoAfterCreation = "etc"
#			}
#			
#			TDECertificateOrAnotherCertificateHere = @{
#				# InfoHereToCreateFromScratch = "or whatever"
# 				# could also be a STREAM of bytes (pulled from a security service/promise/lookup/whatever) that creates the cert as well... 
#			}
#		}
#	}
	#endregion 
	
	DataCollectorSets = @{
		"{~ANY~}" = @{
			Name 				  = "{~DYNAMIC~}"
			Enabled			      = $false
			XmlDefinition		  = "{~DYNAMIC~}"
			EnableStartWithOS	  = $false
			DaysWorthOfLogsToKeep = 90
		}
	}
	
	ExtendedEvents = @{
		"{~SQLINSTANCE~}" = @{
			DisableTelemetry = $true
			DefaultXelDirectory  = "D:\Traces"
			
			BlockedProcessThreshold = 0  # can be set to 2 or whatever... as a default
			
			Sessions = @{
				"{~ANY~}" = @{
					SessionName	    = "{~PARENT~}"
					Enabled		    = $true
					
					DefinitionFile  = "{~DYNAMIC~}" # defaults, by convention, to [SessionName].sql - but CAN, obviously, be overridden
					StartWithSystem = $false
					
					# 'advanced' defaults: 
					XelFileSizeMb   = 100
					XelFileCount    = 6
					XelFilePath	    = "D:\Traces"
				}
			}
		}
	}
	
	SqlServerManagementStudio = @{
		InstallSsms	       	= $false
		Binary 			 	= "{~DEFAULT_PROHIBITED~}"
		IncludeAzureStudio 	= $false
		InstallPath	       	= "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18"
	}
	
	ClusterConfiguration = @{
		"{~SQLINSTANCE~}" = @{
			ClusterType	     = "NONE" # OPTIONS: [ NONE | AG | FCI | WORKGROUP-AG | SCALEOUT-AG | MULTINODE-FCI ]
			EvictionBehavior = "WARN" # If ALREADY part of a cluster but ClusterType = "NONE". Options: [ NONE | WARN | ABORT | FORCE-EVICTION]
			
			ClusterName	     = "{~DEFAULT_PROHIBITED~}"
			ClusterNodes	 = @("{~EMPTY_ARRAY~}") # each 'node' will only attempt to a) create cluster (with itself if no cluster exists) OR b) add itself to cluster if should be part of node. 
			ClusterIPs	     = @("{~EMPTY_ARRAY~}") # IPs behave like nodes (i.e., same behavior as above)
			
			ClusterDisks	 = @("{~EMPTY_ARRAY~}") # ONLY for FCIs - and not implemented yet... 
			
			Witness		     = @{
				# will check for whichever ONE of the following is NOT empty (or, if they're all empty, no witness).
				FileShareWitness  = "{~EMPTY~}"
				DiskWitness	      = "{~EMPTY~}"
				AzureCloudWitness = "{~EMPTY~}" # hmmm. I need an accountNAME and an accountKey here... so... just need to sort that out... 
				Quorum		      = $false # Refactor, this should probably be QuorumMajority vs 'just' Quorum
			}
			
			GenerateClusterSpns = $false
		}
	}
	
	AvailabilityGroups = @{
		"{~SQLINSTANCE~}" = @{
			#EnabledOrStrictEnabled = "probably need 2x keys/entries here... but idea is a) configure AG membership or not? and b) what if ... we find the server as PART of an AG that's NOT defined below?"
			Enabled			        = $true
			EvictionBehavior  = "WARN"
			
			AlwaysOnXeHealthEnabled = $true;
			
			MirroringEndpoint	   = @{
				Enabled					= $false
				Name			    	= "HADR"
				PortNumber				= 5022
				EncryptionAlgorithm   	= "AES"
				EndpointOwner	    	= "sa"
				GrantConnect 			= @("{~EMPTY_ARRAY~}")
			}
			
			SynchronizationChecks  = @{
				DefinePartnerLinkedServer	= $false
				SyncCheckJobs		   		= $false
				AddFailoverProcessing  		= $true
				CreateDisabledJobCategory 	= $false
			}
			
			Groups = @{
				"{~ANY~}" = @{
					ConfigurationAction   = "NONE" # Options would be ??? NONE, ADD, EXTEND? , REMOVE? ... need to give this a bit more thought. And, might not even WANT an 'action' option. which... is a problem cuz i'm trying to key a bunch of "is key valid" stuff off of whether this exists or not... '
					
					# TODO: need a bit more thought on this particular node (ReplicaType) name... 
					ReplicaType = "READ_WRITE" # could be READONLY? 					
					
					ReplicaNodes = @("{~EMPTY~}")
					
					Seeding  = @{
						# Hmmm... options would somewhat include: Auto, some sort of file path, or backups/restore + ... file-path... 
					}
					
					ExpectedDatabases = @("{~EMPTY_ARRAY~}")
					
					Listener = @{
						Name			    = "{~DEFAULT_PROHIBITED~}"
						PortNumber		    = 1433
						IPs				    = @("{~EMPTY_ARRAY~}")
						
						ReadOnlyRounting    = @("{~EMPTY_ARRAY~}")
						
						GenerateListenerSPN = $false
					}
				}
			}
		}
	}
	
	ResourceGovernor = @{
		"{~SQLINSTANCE~}" = @{
			Enabled   = $false # default to off by default. 
			
			# actually, might need ... thingies AND pools? i.e., might need 2x different collections of thingies - which could have ~ANY~ names... 
			
			Pools = @{
				"{~ANY~}" = @{
					
					PoolNameOrWhatever = "{~PARENT~}"
				}
			}
		}
	}
	
	#	CustomScripts {
#		# Custom powershell scripts... in various groups. 
#	}
	
	CustomSqlScripts = @{   # or, call this just 'SqlScripts'?
		"{~SQLINSTANCE~}" = @{
			Deploy = $false  # this probably makes more sense 'down' inside the script groups themselves? 
			
			# _MAY_ end up configuring this (behind the scenes) so that there's a single, default, script group - similar to MSSQLSERVER for sql instances..
			# 		or, that MAY end up being too much of a pain and i may require explicit groups... 
			ScriptGroups = @{  # also, not sure that I need this 'parent' group here at all. i.e., think I can have 'global' values IF needed. but simple 'groups' as parts[1] and be JUST FINE.
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