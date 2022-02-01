Set-StrictMode -Version 1.0;

Surface AdminDbRestoreTests {
	
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	Group-Definitions -GroupKey "AdminDb.*" {
		Definition "RestoreTestsEnabled" -ExpectValueForChildKey "RestoreTestJobs.Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedJobName = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobName");
				
				$start = Get-AgentJobStartTime -SqlServerAgentJob $expectedJobName -SqlServerInstanceName $instanceName;
				
				if ($start -like "<*") {
					return $start;
				}
				
				return $true;
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				$expectedJobName = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobName");
				
				if ($expectedSetting) {
					
					$restoreJobName = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobName");
					$restoreJobStart = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobStartTime");
					$restoreJobTimeZone = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.TimeZoneForUtcOffset");
					$restoreJobCategory = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobCategoryName");
					$allowSecondaries = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.AllowForSecondaries");
					$dbsToRestore = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.DatabasesToRestore");
					$dbsToExclude = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.DatabasesToExclude");
					$priorities = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.Priorities");
					$backupsRoot = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.BackupsRootPath");
					$restoreDataRoot = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.RestoreDataPath");
					$restoreLogRoot = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.RestoreLogsPath");
					$restorePattern = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.RestoredDbNamePattern");
					$allowReplace = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.AllowReplace");
					$rpoThreshold = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.RpoThreshold");
					$dropAfterRestore = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.DropDbsAfterRestore");
					$maxFailedDrops = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.MaxFailedDrops");
					$restoreOperator = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.Operator");
					$restoreProfile = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.Profile");
					$emailPrefix = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobEmailPrefix");
					
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
				
				return Get-AgentJobStartTime -SqlServerAgentJob $expectedJobName -SqlServerInstanceName $instanceName;
			}
		}
		
		Definition "DatabasesToRestore" -ExpectValueForChildKey "RestoreTestJobs.DatabasesToRestore"  -ConfiguredBy "RestoreTestsEnabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedJobName = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobName");
				
				
				$jobStepBody = Get-AgentJobStepBody -SqlServerAgentJob $expectedJobName -JobStepName "Restore Tests" -SqlServerInstanceName $instanceName;
				
				if ($jobStepBody -like "<*") {
					return $jobStepBody;
				}
					
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