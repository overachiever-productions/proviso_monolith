Set-StrictMode -Version 1.0;

filter Get-ProvisoConfigCompoundValues {
	
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$Config,
		[Parameter(Mandatory)]
		[string]$FullCompoundKey,
		[switch]$OrderDescending = $false
	);
	
	$keys = Get-ProvisoConfigValueByKey -Config $Config -Key $FullCompoundKey;
}

# REFACTOR: https://overachieverllc.atlassian.net/browse/PRO-178
filter Get-ProvisoConfigDefault {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Key,
		[switch]$ValidateOnly = $false # validate vs return values... 
	);
	
	$defaultValue = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $Key;
	
	# NOTE: this is kind of BS... i have to put the STRING to the left in these evaluations - otherwise a value of $True will trigger as TRUE and complete the -eq ... 
	if ("{~DEFAULT_PROHIBITED~}" -eq $defaultValue) {
		if ($ValidateOnly) {
			return $true;
		}
		else {
			$defaultValue = $null;
		}
	}
	
	if ("{~DYNAMIC~}" -eq $defaultValue) {
		switch ($Key) {
			{
				$_ -like '*SqlTempDbFileCount'
			} {
				$coreCount = Get-WindowsCoreCount;
				if ($coreCount -le 4) {
					return $coreCount;
				}
				return 4;
			}
			default {
				throw "Proviso Framework Error. Invalid {~DYNAMIC~} default provided for key: [$Key].";
			}
		}
	}
	
	if ($null -ne $defaultValue) {
		return $defaultValue;
	}
	
	# Non-SQL-Instance Partials (pattern):
	$match = [regex]::Matches($Key, '(Host\.NetworkDefinitions|Host\.LocalAdministrators|Host\.ExpectedDisks|ExpectedShares|AvailabilityGroups)\.(?<partialName>[^\.]+)');
	if ($match) {
		$partialName = $match[0].Groups['partialName'];
		
		if (-not ([string]::IsNullOrEmpty($partialName))) {
			$nonSqlPartialKey = $Key.Replace($partialName, '{~ANY~}');
			
			$defaultValue = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $nonSqlPartialKey;
			
			if ($null -ne $defaultValue) {
				if ($ValidateOnly -and ($defaultValue.GetType() -in "hashtable", "System.Collections.Hashtable", "system.object[]")) {
					return $defaultValue;
				}
				
				if ($defaultValue -eq "{~PARENT~}") {
					$defaultValue = $partialName;
				}
				
				if ($null -ne $defaultValue) {
					return ($defaultValue).Value;
				}
			}
			
			if ($ValidateOnly) {
				return ($partialName).Value;
			}
		}
	}
	
	# Address wildcards: 
	# 	NOTE: I COULD have used 1x regex (that combined instance AND other details), but went with SRP (i.e., each regex is for ONE thing):
	$match = [regex]::Matches($Key, '(ExpectedDirectories|SqlServerInstallation|SqlServerConfiguration|SqlServerPatches|AdminDb|ExtendedEvents|ResourceGovernor|CustomSqlScripts)\.MSSQLSERVER');
	if ($match) {
		$keyWithoutDefaultMSSQLServerName = $Key.Replace('MSSQLSERVER', '{~ANY~}');
		$output = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $keyWithoutDefaultMSSQLServerName;
		
		if ($null -ne $output) {
			return $output;
		}
	}
	
	return $null;
}

function Get-ProvisoConfigGroupNames {
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$Config,
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$GroupKey,
		[string]$OrderByKey
	);
	
	begin {
		# do validations/etc. 
		$decrementKey = [int]::MaxValue;
	};
	
	process {
		$block = Get-ProvisoConfigValueByKey -Config $Config -Key $GroupKey;
		$keys = $block.Keys;
		
		if ($OrderByKey) {
			
			$prioritizedKeys = New-Object "System.Collections.Generic.SortedDictionary[int, string]";
			
			foreach ($key in $keys) {
				$orderingKey = "$GroupKey.$key.$OrderByKey";
				
				$priority = Get-ProvisoConfigValueByKey -Key $orderingKey -Config $Config;
				if (-not ($priority)) {
					$decrementKey = $decrementKey - 1;
					$priority = $decrementKey;
				}
				
				$prioritizedKeys.Add($priority, $key);
			}
			
			$keys = @();
			foreach ($orderedKey in $prioritizedKeys.GetEnumerator()) {
				$keys += $orderedKey.Value;
			}
		}
	};
	
	end {
		return $keys;
	};
}

filter Get-ProvisoConfigValueByKey {
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$Config,
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	$keys = $Key -split "\.";
	$output = $null;
	# vNext: I presume there's a more elegant way to do this... but, it works and ... I don't care THAT much.
	switch ($keys.Count) {
		1 {
			$output = $Config.($keys[0]);
		}
		2 {
			$output = $Config.($keys[0]).($keys[1]);
		}
		3 {
			$output = $Config.($keys[0]).($keys[1]).($keys[2]);
		}
		4 {
			$output = $Config.($keys[0]).($keys[1]).($keys[2]).($keys[3]);
		}
		5 {
			$output = $Config.($keys[0]).($keys[1]).($keys[2]).($keys[3]).($keys[4]);
		}
		default {
			throw "Invalid Key. Too many key segments defined.";
		}
	}
	
	return $output;
}

filter Set-ProvisoConfigValueByKey {
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$Config,
		[Parameter(Mandatory)]
		[string]$Key,
		[Parameter(Mandatory)]
		[string]$Value
	);
	
	$keys = $Key -split "\.";
	$output = $null;
	# vNext: I presume there's a more elegant way to do this... but, it works and ... I don't care THAT much.
	switch ($keys.Count) {
		1 {
			$Config.($keys[0]) = $Value;
		}
		2 {
			$Config.($keys[0]).($keys[1]) = $Value;
		}
		3 {
			$Config.($keys[0]).($keys[1]).($keys[2]) = $Value;
		}
		4 {
			$Config.($keys[0]).($keys[1]).($keys[2]).($keys[3]) = $Value;
		}
		5 {
			$Config.($keys[0]).($keys[1]).($keys[2]).($keys[3]).($keys[4]) = $Value;
		}
		default {
			throw "Invalid Key. Too many key segments defined.";
		}
	}
}

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
		# NOTE: Data Collector Sets do NOT have an instance... 
		"{~ANY~}" = @{
			Enabled			      = $false
			EnableStartWithOS	  = $false
			DaysWorthOfLogsToKeep = 180
		}
	}
	
	ExtendedEvents = @{
		"{~ANY~}" = @{
			DisableTelemetry = $true
		}
	}
	
	SqlServerManagementStudio = @{
		InstallSsms	       = $false
		IncludeAzureStudio = $false
		InstallPath	       = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18"
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