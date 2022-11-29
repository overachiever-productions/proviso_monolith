Set-StrictMode -Version 1.0;

Surface AdminDbHistory -Target "AdminDb" {
	Assertions {
		Assert-SqlServerIsInstalled -ConfigureOnly;
		Assert-AdminDbInstalled -ConfigureOnly;
	}
	
	# TODO: add in the abililty to change the NAME of the JOB that handles these cleanups.
	Aspect -Scope "HistoryManagement" {
		Facet "CleanupEnabled" -Key "Enabled" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$state = Get-AgentJobStartTime -SqlServerAgentJob "Regular History Cleanup" -SqlServerInstanceName $instanceName;
				if ($state -like "<*") {
					return $state;
				}
				
				return $true;
			}
		}
		
		Facet "SQLServerLogsToKeep" -Key "SqlServerLogsToKeep" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				
				# could read the registry directly... but INSTANCE_reg_read is nice/easy
				$count = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "DECLARE @NumberOfServerLogsToKeep int;
					EXEC sys.xp_instance_regread 
						N'HKEY_LOCAL_MACHINE', 
						N'Software\Microsoft\MSSQLServer\MSSQLServer', 
						N'NumErrorLogs', 
						@NumberOfServerLogsToKeep OUTPUT;
					SELECT @NumberOfServerLogsToKeep [setting]; ").setting;
				
				return $count;
			}
		}
		
		Facet "AgentJobHistory" -Key "AgentJobHistoryRetention" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$retentionSettings = $PVContext.CurrentConfigKeyValue;				
				$jobStepBody = Get-AgentJobStepBody -SqlServerAgentJob "Regular History Cleanup" -JobStepName "Truncate Job History" -SqlServerInstanceName $instanceName;
				if ($jobStepBody -like "<*") {
					return $jobStepBody;
				}
				
				$regex = New-Object System.Text.RegularExpressions.Regex('DAY, 0 - (?<days>[0-9]{1,4})', [System.Text.RegularExpressions.RegexOptions]::Multiline);
				$matches = $regex.Match($jobStepBody);
				if ($matches) {
					$days = $matches.Groups[1].Value;
					
					return Translate-AdminDbVectorFromDays -Days $days -ComparisonVectorFormat $retentionSettings;
				}
			}
		}
		
		Facet "BackupHistory" -Key "BackupHistoryRetention" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$retentionSettings = $PVContext.CurrentConfigKeyValue;				
				$jobStepBody = Get-AgentJobStepBody -SqlServerAgentJob "Regular History Cleanup" -JobStepName "Truncate Backup History" -SqlServerInstanceName $instanceName;
				if ($jobStepBody -like "<*") {
					return $jobStepBody;
				}
				
				$regex = New-Object System.Text.RegularExpressions.Regex('DAY, 0 - (?<days>[0-9]{1,4})', [System.Text.RegularExpressions.RegexOptions]::Multiline);
				$matches = $regex.Match($jobStepBody);
				if ($matches) {
					$days = $matches.Groups[1].Value;
					
					return Translate-AdminDbVectorFromDays -Days $days -ComparisonVectorFormat $retentionSettings;
				}
			}
		}
		
		Facet "EmailHistory" -Key "EmailHistoryRetention" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$retentionSettings = $PVContext.CurrentConfigKeyValue;				
				$jobStepBody = Get-AgentJobStepBody -SqlServerAgentJob "Regular History Cleanup" -JobStepName "Truncate Email History" -SqlServerInstanceName $instanceName;
				if ($jobStepBody -like "<*") {
					return $jobStepBody;
				}
				
				$regex = New-Object System.Text.RegularExpressions.Regex('DAY, 0 - (?<days>[0-9]{1,4})', [System.Text.RegularExpressions.RegexOptions]::Multiline);
				$matches = $regex.Match($jobStepBody);
				if ($matches) {
					$days = $matches.Groups[1].Value;
					
					return Translate-AdminDbVectorFromDays -Days $days -ComparisonVectorFormat $retentionSettings;
				}
			}
		}
		
		# TODO: Implement -Detailed facets for FTI cleanup and so on... 
		
		Build {
			$sqlServerInstance = $PVContext.CurrentSqlInstance;
			$facetName = $PVContext.CurrentFacetName;
			$matched = $PVContext.Matched;
			$expected = $PVContext.Expected;
			
			if ($false -eq $expected) {
				switch ($facetName) {
					"CleanupEnabled" {
						$PVContext.WriteLog("Config setting for [Admindb.$sqlServerInstance.HistoryManagement.Enabled] is set to `$false - but a Job Entitled 'Regular History Cleanup' already exists. Proviso will NOT drop this job. Please make changes manually.", "Critical");
						#$jobName = $PVConfig.GetValue("AdminDb.$sqlServerInstance.RestoreTestJobs.JobName");
						#$PVContext.WriteLog("Config setting for [Admindb.$sqlServerInstance.RestoreTests.Enabled] is set to `$false - but a job entitled [$jobName] already exists. Proviso will NOT drop this job. Please make changes manually.", "Critical");
						return; # i.e., don't LOAD current instance-name as a name that needs to be configured (all'z that'd do would be to re-run SETUP... not tear-down.);
					}
				}
			}
			
			if (-not ($matched)) {
				$currentInstances = $PVContext.GetSurfaceState("TargetInstances");
				if ($null -eq $currentInstances) {
					$currentInstances = @();
				}
				
				if ($currentInstances -notcontains $sqlServerInstance) {
					$currentInstances += $sqlServerInstance
				}
				
				$PVContext.SetSurfaceState("TargetInstances", $currentInstances);
			}
			
		}
		
		Deploy {
			$currentInstances = $PVContext.GetSurfaceState("TargetInstances");
			
			foreach ($instanceName in $currentInstances) {
				[string]$logCount = $PVConfig.GetValue("AdminDb.$instanceName.HistoryManagement.SqlServerLogsToKeep");
				[string]$agentJobRetention = $PVConfig.GetValue("AdminDb.$instanceName.HistoryManagement.AgentJobHistoryRetention");
				[string]$backupHistory = $PVConfig.GetValue("AdminDb.$instanceName.HistoryManagement.BackupHistoryRetention");
				[string]$emailRetention = $PVConfig.GetValue("AdminDb.$instanceName.HistoryManagement.EmailHistoryRetention");
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "EXEC admindb.dbo.[manage_server_history]
						@NumberOfServerLogsToKeep = $logCount,
						@AgentJobHistoryRetention = N'$agentJobRetention',
						@BackupHistoryRetention = N'$backupHistory',
						@EmailHistoryRetention = N'$emailRetention', 
						@OverWriteExistingJob = 1; ";
			}
			
		}
	}
}