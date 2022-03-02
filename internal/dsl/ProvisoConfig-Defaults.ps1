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
			"Administrator" # TODO: this is a HACK... 
			"Administrator"
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
				VolumeLabel		     = "{~PARENT~}"
			}
		}
	}
	
	ExpectedDirectories = @{
		"{~SQLINSTANCE~}" = @{
			VirtualSqlServerServiceAccessibleDirectories = @()
			RawDirectories = @()
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
		"{~SQLINSTANCE~}" = @{
			SqlExePath	      = "{~DEFAULT_PROHIBITED~}"
			StrictInstallOnly = $true
			
			Setup			  = @{
				Version				      = ""
				Edition				      = ""
				
				Features				  = "{~DEFAULT_PROHIBITED~}"
				Collation				  = "SQL_Latin1_General_CP1_CI_AS"
				InstantFileInit		      = $true
				
				InstallDirectory		  = "{~DEFAULT_PROHIBITED~}"
				InstallSharedDirectory    = "{~DEFAULT_PROHIBITED~}"
				InstallSharedWowDirectory = "{~DEFAULT_PROHIBITED~}"
				
				SqlTempDbFileCount	      = "{~DYNAMIC~}" # 4 or .5 * core-count (whichever is larger)
				SqlTempDbFileSize		  = 1024
				SqlTempDbFileGrowth	      = 256
				SqlTempDbLogFileSize	  = 2048
				SqlTempDbLogFileGrowth    = 256
				
				FileStreamLevel		      = 0
				
				NamedPipesEnabled		  = $false
				TcpEnabled			      = $true
				
				LicenseKey			      = ""
			}
			
			ServiceAccounts   = @{
				SqlServiceAccountName	    = "{~DYNAMIC~}"
				SqlServiceAccountPassword   = ""
				AgentServiceAccountName	    = "{~DYNAMIC~}"
				AgentServiceAccountPassword = ""
				FullTextServiceAccount	    = "{~DYNAMIC~}"
				FullTextServicePassword	    = ""
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
				MembersOfSysAdmin	  = @(
				)
			}
		}
		
		MSSQLSERVER = @{
			SqlExePath	      = "{~DEFAULT_PROHIBITED~}"
			StrictInstallOnly = $true
			
			Setup			  = @{
				Version				      = ""
				Edition				      = ""
				
				Features				  = "{~DEFAULT_PROHIBITED~}"
				Collation				  = "SQL_Latin1_General_CP1_CI_AS"
				InstantFileInit		      = $true
				
				InstallDirectory		  = "C:\Program Files\Microsoft SQL Server"
				InstallSharedDirectory    = "C:\Program Files\Microsoft SQL Server"
				InstallSharedWowDirectory = "C:\Program Files (x86)\Microsoft SQL Server"
				
				SqlTempDbFileCount	      = "{~DYNAMIC~}"
				SqlTempDbFileSize		  = 1024
				SqlTempDbFileGrowth	      = 256
				SqlTempDbLogFileSize	  = 2048
				SqlTempDbLogFileGrowth    = 256
				
				FileStreamLevel		      = 0
				
				NamedPipesEnabled		  = $false
				TcpEnabled			      = $true
				
				LicenseKey			      = ""
			}
			
			ServiceAccounts   = @{
				SqlServiceAccountName	    = "NT SERVICE\MSSQLSERVER"
				SqlServiceAccountPassword   = ""
				AgentServiceAccountName	    = "NT SERVICE\SQLSERVERAGENT"
				AgentServiceAccountPassword = ""
				FullTextServiceAccount	    = "NT SERVICE\MSSQLFDLauncher"
				FullTextServicePassword	    = ""
			}
			
			SqlServerDefaultDirectories = @{
				InstallSqlDataDir = "D:\SQLData"
				SqlDataPath	      = "D:\SQLData"
				SqlLogsPath	      = "D:\SQLData"
				SqlBackupsPath    = "D:\SQLBackups"
				TempDbPath	      = "D:\SQLData"
				TempDbLogsPath    = "D:\SQLData"
			}
			
			SecuritySetup	  = @{
				EnableSqlAuth		  = $true
				AddCurrentUserAsAdmin = $false
				SaPassword		      = "{~DEFAULT_PROHIBITED~}"
				MembersOfSysAdmin	  = @(
				)
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
		}
	}
	
	AdminDb = @{
		"{~SQLINSTANCE~}" = @{
			
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
				Enabled				     = $true
				# TODO: add a jobName: "Regular History Cleanup"
				SqlServerLogsToKeep	     = 18
				AgentJobHistoryRetention = "6 weeks"
				BackupHistoryRetention   = "6 weeks"
				EmailHistoryRetention    = "6 months"
			}
			
			DiskMonitoring   = @{
				Enabled			       = $true
				# TODO: add a jobName: "Regular Drive Space Checks"
				WarnWhenFreeGBsGoBelow = "32"
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
			}
			
			ConsistencyChecks = @{
				Enabled					     = $false
				JobName					     = "Database Consistency Checks"
				ExecutionDays			     = "M,W,F,Su"
				StartTime				     = "04:10:00"
				Targets					     = "{USER}"
				Exclusions				     = ""
				Priorities				     = ""
				IncludeExtendedLogicalChecks = $false
				TimeZoneForUtcOffset		 = "" # vNEXT, make this one {~DYNAMIC~} 
				JobCategoryName			     = "Database Maintenance"
				Operator					 = "Alerts"
				Profile					     = "General"
				JobEmailPrefix			     = "[Database Corruption Checks] - "
			}
			
			BackupJobs	     = @{
				Enabled					    = $true
				JobsNamePrefix			    = "Database Backups - "
				
				UserDatabasesToBackup	    = "{USER}"
				UserDbsToExclude		    = ""
				CertificateName			    = ""
				BackupDirectory			    = "{DEFAULT}"
				CopyToDirectory			    = ""
				SystemBackupRetention	    = "4 days"
				CopyToSystemBackupRetention = "4 days" # todo, have this default to whatever is set for SystemBackupRetention - i.e., if they set that to 5 days, this is 5 days... 
				UserBackupRetention		    = "3 days"
				CopyToUserBackupRetention   = "3 days" # ditto. and, of course, none of these 'matter' unless there's a CopyToDirectory specified
				LogBackupRetention		    = "73 hours"
				CopyToLogBackupRetention    = "73 hours" # ditto
				AllowForSecondaries		    = $false
				SystemBackupsStart		    = "18:50:00"
				UserBackupsStart		    = "02:00:00"
				DiffBackupsStart		    = ""
				DiffBackupsEvery		    = ""
				LogBackupsStart			    = "00:02:00"
				LogBackupsEvery			    = "10 minutes"
				TimeZoneForUtcOffset	    = ""
				JobsCategoryName		    = "Backups"
				Operator				    = "Alerts"
				Profile					    = "General"
			}
			
			RestoreTestJobs  = @{
				Enabled			      = $false
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
				JobEmailPrefix	      = "[RESTORE TEST] - "
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
		"{~ANY~}" = @{
			Enabled			      = $false
			EnableStartWithOS	  = $false
			DaysWorthOfLogsToKeep = 180
		}
	}
	
	ExtendedEvents = @{
		"{~SQLINSTANCE~}" = @{
			DisableTelemetry = $true
		}
	}
	
	SqlServerManagementStudio = @{
		InstallSsms	       = $false
		IncludeAzureStudio = $false
		InstallPath	       = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18"
	}
	
	ResourceGovernor = @{
		"{~SQLINSTANCE~}" = @{
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
	}
	
	CustomSqlScripts = @{
		"{~SQLINSTANCE~}" = @{
			Deploy = $false
		}
	}
}