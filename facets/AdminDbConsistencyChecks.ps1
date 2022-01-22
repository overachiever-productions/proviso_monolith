Set-StrictMode -Version 1.0;

Facet AdminDbConsistencyChecks {
	
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	Group-Definitions -GroupKey "AdminDb.*" {
		Definition "ConsistencyCheckJobEnabled" -ExpectValueForChildKey "ConsistencyChecks.Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$jobName = "Database Consistency Checks";
				
				$state = Report-SqlServerAgentJobEnabledState -SqlServerAgentJob $jobName -SqlServerInstanceName $instanceName;
				
				if ($expectedSetting) {
					return $state;
				}
				else {
					if ($null -eq $state) {
						return $false;		# don't output <EMPTY> when we're tryign to account for true/false WHEN the job should NOT be configured (i.e., return FALSE so that expected and actual match)
					}
					
					return $state;
				}
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				if ($expectedSetting) {
					
					$weekDays = $PVConfig.GetValue("AdminDb.IndexMaintenance.DailyJobRunsOnDays");
					$weekEnds = $PVConfig.GetValue("AdminDb.IndexMaintenance.WeekendJobRunsOnDays");
					$ixJobStartTime = $PVConfig.GetValue("AdminDb.IndexMaintenance.StartTime");
					$ixJobTimeZone = $PVConfig.GetValue("AdminDb.IndexMaintenance.TimeZoneForUtcOffset");
					$ixJobPrefix = $PVConfig.GetValue("AdminDb.IndexMaintenance.JobsNamePrefix");
					$ixJobCategory = $PVConfig.GetValue("AdminDb.IndexMaintenance.JobsCategoryName");
					$ixJobOperator = $PVConfig.GetValue("AdminDb.IndexMaintenance.OperatorToAlertOnErrors");
					
					
					Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "EXEC admindb.dbo.[create_index_maintenance_jobs]
						@DailyJobRunsOnDays = N'$weekDays',
						@WeekendJobRunsOnDays = N'$weekEnds',
						@IXMaintenanceJobStartTime = N'$ixJobStartTime',
						@TimeZoneForUtcOffset = N'$ixJobTimeZone',
						@JobsNamePrefix = N'$ixJobPrefix',
						@JobsCategoryName = N'$ixJobCategory',
						@JobOperatorToAlertOnErrors = N'$ixJobOperator',
						@OverWriteExistingJobs = 1; ";
					
				}
				else {
					if ($PVContext.Actual) {
						$PVContext.WriteLog("Config setting for [Admindb.$instanceName.ConsistencyChecks.Enabled] is set to `$false - but a Consistency Check Job exists. Proviso will NOT drop this job. Please make changes manually.", "Critical");
					}
					# otherwise, expected config was "False" and current config is "False";
					# crap... unless we've got deferred.
					# see comment for https://overachieverllc.atlassian.net/browse/PRO-201
				}
			}
		}
		
		Definition "ConsistencyCheckDays" -ConfiguredBy "ConsistencyCheckJobEnabled" {
			Expect {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedDays = $PVConfig.GetValue("AdminDb.$instanceName.ConsistencyChecks.ExecutionDays");
				
				return $expectedDays -replace " ", "";
			}
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$jobName = "Database Consistency Checks";
				$state = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "EXEC admindb.dbo.extract_agentjob_weeklyschedule_days N'$jobName'; ").Outcome;
				
				if ($expectedSetting) {
					return $state; # this SHOULD be the M, W, F, Su or whatever value we EXPECT... 
				}
				else {
					$ignored = "NOTFOUND", "DISABLED", "SCHEDULE_DISABLED", "NO_SCHEDULE";
					if ($ignored -contains $state) {
						return "";
					}
					
					return $state;
				}
			}
		}
		
		Definition "Targets" -ExpectValueForChildKey "ConsistencyChecks.Targets" -ConfiguredBy "ConsistencyCheckJobEnabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$jobName = "Database Consistency Checks";
				$jobStepBody = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [command] FROM [msdb].dbo.[sysjobsteps] WHERE [step_name] = 'Check Database Consistency' AND [job_id] = (SELECT [job_id] FROM [msdb].dbo.[sysjobs] WHERE [name] = N'$jobName'); ").command;
				
				$regex = New-Object System.Text.RegularExpressions.Regex("@Targets = N'(?<targets>[^']+)", [System.Text.RegularExpressions.RegexOptions]::Multiline);
				$matches = $regex.Match($jobStepBody);
				if ($matches) {
					$targets = $matches.Groups[1].Value;
					
					return $targets;
				}
			}
		}
		
		Definition "StartTime" -ExpectValueForChildKey "ConsistencyChecks.StartTime" -ConfiguredBy "ConsistencyCheckJobEnabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$jobName = "Database Consistency Checks";
				$start = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "EXEC admindb.dbo.extract_agentjob_starttime N'$jobName'; ").Outcome;
				return $start;
			}
		}		
		
		# TODO: implement -IsDetailed definitions here. 
	}
}