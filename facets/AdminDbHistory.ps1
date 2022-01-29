Set-StrictMode -Version 1.0;

Facet AdminDbHistory {
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	# TODO: add in the abililty to change the NAME of the JOB that handles these cleanups.
	# cuz... for now, the job-name is HARD CODED to 'Regular History Cleanup' (in pretty much ALL of the following validations AND for the configure)
	#   note... i've done with this later facets and ...  the CONFIG is set to allow this (for some 'facets' of admindb config... )
	Group-Definitions -GroupKey "AdminDb.*" {
		Definition "CleanupEnabled" -ExpectValueForChildKey "HistoryManagement.Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$state = Get-AgentJobStartTime -SqlServerAgentJob "Regular History Cleanup" -SqlServerInstanceName $instanceName;
				if ($state -like "<*") {
					return $state;
				}
				
				return $true;
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				if ($expectedSetting) {
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
				else {
					$PVContext.WriteLog("Config setting for [Admindb.$instanceName.HistoryManagement.Enabled] is set to `$false - but a Job Entitled 'Regular History Cleanup' already exists. Proviso will NOT drop this job. Please make changes manually.", "Critical");
				}
			}
		}
		
		Definition "SQLServerLogsToKeep" -ExpectValueForChildKey "HistoryManagement.SqlServerLogsToKeep" -ConfiguredBy "CleanupEnabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
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
		
		Definition "AgentJobHistory" -ExpectValueForChildKey "HistoryManagement.AgentJobHistoryRetention" -ConfiguredBy "CleanupEnabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$retentionSettings = $PVContext.CurrentChildKeyValue;
				
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
		
		Definition "BackupHistory" -ExpectValueForChildKey "HistoryManagement.BackupHistoryRetention" -ConfiguredBy "CleanupEnabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$retentionSettings = $PVContext.CurrentChildKeyValue;
				
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
		
		Definition "EmailHistory" -ExpectValueForChildKey "HistoryManagement.EmailHistoryRetention" -ConfiguredBy "CleanupEnabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$retentionSettings = $PVContext.CurrentChildKeyValue;
				
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
		
		# TODO: Implement -Detailed definitions for FTI cleanup and so on... 
	}
}