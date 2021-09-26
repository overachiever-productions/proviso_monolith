Set-StrictMode -Version 1.0;

[PSCustomObject]$script:Proviso_Config_Defaults = [PSCustomObject]@{
	
	Host = @{
		
		#TargetServer = NOT SPECIFIED AS A DEFAULT
		#TargetDOMAIN = NOT SPECIFIED AS A DEFAULT 
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
			WsfcComponents				     = $false
			NetFxForPre2016InstancesRequired = $false
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
			StrictInstallOnly = $true
			
			SecuritySetup	  = @{
				EnableSqlAuth		  = $false
				AddCurrentUserAsAdmin = $false
				SaPassword		      = ""
				MembersOfSysAdmin	  = @(
				)
			}
			
			LicenseKey	      = ""
		}
		
		MSSQLSERVER = @{
			StrictInstallOnly = $true
			
			ServiceAccounts   = @{
				SqlServiceAccountName	    = "NT SERVICE\MSSQLSERVER"
				SqlServiceAccountPassword   = ""
				AgentServiceAccountName	    = "NT Service\SQLSERVERAGENT"
				AgentServiceAccountPassword = ""
			}
			
			SecuritySetup	  = @{
				EnableSqlAuth			    = $false
				AddCurrentUserAsAdmin	    = $false
				SaPassword				    = ""
				MembersOfSysAdmin		    = @(
				)
			}
			
			# COULD specify C:\etc. but... would rather THROW exceptions for values not found than default data/etc. to C:\ drive. 
			SqlServerDefaultDirectories = @{
			}
			
			LicenseKey	      = ""
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