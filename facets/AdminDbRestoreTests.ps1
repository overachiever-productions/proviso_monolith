Set-StrictMode -Version 1.0;

Facet AdminDbRestoreTests {
	
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	Group-Definitions -GroupKey "AdminDb.*" {
		Definition "RestoreTestsEnabled" -ExpectValueForChildKey "RestoreTestJobs.Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedJobName = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobName");
				
				Report-SqlServerAgentJobEnabledState -SqlServerAgentJob $expectedJobName -SqlServerInstanceName $instanceName;
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				$expectedJobName = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobName");
				
				if ($expectedSetting) {
					
					$restoreJobName = $PVConfig.GetValue("AdminDb.RestoreTestJobs.JobName");
					$restoreJobStart = $PVConfig.GetValue("AdminDb.RestoreTestJobs.JobStartTime");
					$restoreJobTimeZone = $PVConfig.GetValue("AdminDb.RestoreTestJobs.TimeZoneForUtcOffset");
					$restoreJobCategory = $PVConfig.GetValue("AdminDb.RestoreTestJobs.JobCategoryName");
					$allowSecondaries = $PVConfig.GetValue("AdminDb.RestoreTestJobs.AllowForSecondaries");
					$dbsToRestore = $PVConfig.GetValue("AdminDb.RestoreTestJobs.DatabasesToRestore");
					$dbsToExclude = $PVConfig.GetValue("AdminDb.RestoreTestJobs.DatabasesToExclude");
					$priorities = $PVConfig.GetValue("AdminDb.RestoreTestJobs.Priorities");
					$backupsRoot = $PVConfig.GetValue("AdminDb.RestoreTestJobs.BackupsRootPath");
					$restoreDataRoot = $PVConfig.GetValue("AdminDb.RestoreTestJobs.RestoreDataPath");
					$restoreLogRoot = $PVConfig.GetValue("AdminDb.RestoreTestJobs.RestoreLogsPath");
					$restorePattern = $PVConfig.GetValue("AdminDb.RestoreTestJobs.RestoredDbNamePattern");
					$allowReplace = $PVConfig.GetValue("AdminDb.RestoreTestJobs.AllowReplace");
					$rpoThreshold = $PVConfig.GetValue("AdminDb.RestoreTestJobs.RpoThreshold");
					$dropAfterRestore = $PVConfig.GetValue("AdminDb.RestoreTestJobs.DropDbsAfterRestore");
					$maxFailedDrops = $PVConfig.GetValue("AdminDb.RestoreTestJobs.MaxFailedDrops");
					$restoreOperator = $PVConfig.GetValue("AdminDb.RestoreTestJobs.Operator");
					$restoreProfile = $PVConfig.GetValue("AdminDb.RestoreTestJobs.Profile");
					$emailPrefix = $PVConfig.GetValue("AdminDb.RestoreTestJobs.JobEmailPrefix");
					
					$secondaries = "0";
					if ($allowSecondaries) {
						$secondaries = "1";
					}
					
					$drop = "0";
					if ($dropAfterRestore) {
						$drop = "1";
					}
					
					Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "EXEC [admindb].[dbo].[create_restore_test_job]
						@JobName = N'$restoreJobName',
						@RestoreTestStartTime = N'$restoreJobStart',
						@TimeZoneForUtcOffset = N'$restoreJobTimeZone',
						@JobCategoryName = N'$restoreJobCategory',
						@AllowForSecondaries = N'$secondaries',
						@DatabasesToRestore = N'$dbsToRestore',
						@DatabasesToExclude = N'$dbsToExclude',
						@Priorities = N'$priorities',
						@BackupsRootPath = N'$backupsRoot',
						@RestoredRootDataPath = N'$restoreDataRoot',
						@RestoredRootLogPath = N'$restoreLogRoot',
						@RestoredDbNamePattern = N'$restorePattern',
						@AllowReplace = N'$allowReplace',
						@RpoWarningThreshold = N'$rpoThreshold',
						@DropDatabasesAfterRestore = $($drop),
						@MaxNumberOfFailedDrops = $maxFailedDrops,
						@OperatorName = N'$restoreOperator',
						@MailProfileName = N'$restoreProfile',
						@EmailSubjectPrefix = N'$emailPrefix',
						@OverWriteExistingJob = 1; ";
					
				}
				else {
					$PVContext.WriteLog("Config setting for [Admindb.$instanceName.RestoreTests.Enabled] is set to `$false - but a job entitled [$expectedJobName] already exists. Proviso will NOT drop this job. Please make changes manually.", "Critical");
				}
			}
		}
		
		Definition "StartTime" -ExpectValueForChildKey "RestoreTestJobs.JobStartTime" -ConfiguredBy "RestoreTestsEnabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedJobName = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobName");
				
				$start = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "EXEC admindb.dbo.extract_agentjob_starttime N'$expectedJobName'; ").Outcome;
				return $start;
			}
		}
		
		Definition "DatabasesToRestore" -ExpectValueForChildKey "RestoreTestJobs.DatabasesToRestore"  -ConfiguredBy "RestoreTestsEnabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedJobName = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobName");
				
				$jobStepBody = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [command] FROM [msdb].dbo.[sysjobsteps] WHERE [step_name] = 'Restore Tests' AND [job_id] = (SELECT [job_id] FROM [msdb].dbo.[sysjobs] WHERE [name] = N'$expectedJobName'); ").command;
				
				$regex = New-Object System.Text.RegularExpressions.Regex("@DatabasesToRestore = N'(?<targets>[^']+)", [System.Text.RegularExpressions.RegexOptions]::Multiline);
				$matches = $regex.Match($jobStepBody);
				if ($matches) {
					$targets = $matches.Groups[1].Value;
					
					return $targets;
				}
			}
		}
		
		# TODO: Implement -Detailed definitions... 
	}
}