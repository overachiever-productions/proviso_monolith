Set-StrictMode -Version 1.0;

Surface AdminDbRestoreTests -Target "AdminDb" {
	
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	Aspect -Scope "RestoreTestJobs" {
		#Facet "RestoreTestsEnabled" -ExpectChildKeyValue "RestoreTestJobs.Enabled" -UsesBuild {
		Facet "RestoreTestsEnabled" -Key "Enabled" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				#$expectedJobName = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobName");
				$expectedJobName = $PVContext.CurrentConfigKeyValue;
				
				$start = Get-AgentJobStartTime -SqlServerAgentJob $expectedJobName -SqlServerInstanceName $instanceName;
				
				if ($start -like "<*") {
					return $start;
				}
				
				return $true;
			}
		}
		
		#Facet "StartTime" -ExpectChildKeyValue "RestoreTestJobs.JobStartTime" -UsesBuild {
		Facet "StartTime" -Key "JobStartTime" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				#$expectedJobName = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobName");
				$expectedJobName = $PVContext.CurrentConfigKeyValue;
				
				return Get-AgentJobStartTime -SqlServerAgentJob $expectedJobName -SqlServerInstanceName $instanceName;
			}
		}
		
		#Facet "DatabasesToRestore" -ExpectChildKeyValue "RestoreTestJobs.DatabasesToRestore"  -UsesBuild {
		Facet "DatabasesToRestore" -Key "DatabasesToRestore" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				#$expectedJobName = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.JobName");
				$expectedJobName = $PVContext.CurrentConfigKeyValue;
				
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
		
		Build {
			$sqlServerInstance = $PVContext.CurrentSqlInstance;
			$facetName = $PVContext.CurrentFacetName;
			$matched = $PVContext.Matched;
			$expected = $PVContext.Expected;
			
			if ($false -eq $expected) {
				switch ($facetName) {
					"RestoreTestsEnabled" {
						$jobName = $PVConfig.GetValue("AdminDb.$sqlServerInstance.RestoreTestJobs.JobName");
						$PVContext.WriteLog("Config setting for [Admindb.$sqlServerInstance.RestoreTests.Enabled] is set to `$false - but a job entitled [$jobName] already exists. Proviso will NOT drop this job. Please make changes manually.", "Critical");
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
				$dropAfterRestore = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.DropDatabasesAfterRestore");
				$maxFailedDrops = $PVConfig.GetValue("AdminDb.$instanceName.RestoreTestJobs.MaxNumberOfFailedDrops");
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
		}
		
		# TODO: Implement -Detailed facets... 
	}
}