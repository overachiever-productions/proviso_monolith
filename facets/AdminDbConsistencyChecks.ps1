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
					
					$dbccStartTime = $PVConfig.GetValue("AdminDb.$instanceName.ConsistencyChecks.StartTime");
					$dbccTargets = $PVConfig.GetValue("AdminDb.$instanceName.ConsistencyChecks.Targets");
					$dbccExclusions = $PVConfig.GetValue("AdminDb.$instanceName.ConsistencyChecks.Exclusions");
					$dbccPriorities = $PVConfig.GetValue("AdminDb.$instanceName.ConsistencyChecks.Priorities");
					$dbccLogicalChecks = $PVConfig.GetValue("AdminDb.$instanceName.ConsistencyChecks.IncludeExtendedLogicalChecks");
					$dbccTimeZone = $PVConfig.GetValue("AdminDb.$instanceName.ConsistencyChecks.TimeZoneForUtcOffset");
					$dbccJobName = $PVConfig.GetValue("AdminDb.$instanceName.ConsistencyChecks.JobName");
					$dbccJobCategoryName = $PVConfig.GetValue("AdminDb.$instanceName.ConsistencyChecks.JobCategoryName");
					$dbccOperator = $PVConfig.GetValue("AdminDb.$instanceName.ConsistencyChecks.Operator");
					$dbccProfile = $PVConfig.GetValue("AdminDb.$instanceName.ConsistencyChecks.Profile");
					$dbccSubject = $PVConfig.GetValue("AdminDb.$instanceName.ConsistencyChecks.JobEmailPrefix");
					
					$dbccExtended = "0";
					if ($dbccLogicalChecks) {
						$dbccExtended = "1";
					}
					
					Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "EXEC admindb.dbo.[create_consistency_checks_job]
						@ExecutionDays = N'$dbccDays', 
						@JobStartTime = N'$dbccStartTime', 
						@JobName = N'$dbccJobName', 
						@JobCategoryName = N'$dbccJobCategoryName', 
						@TimeZoneForUtcOffset = N'$dbccTimeZone', 
						@Targets = N'$dbccTargets', 
						@Exclusions = N'$dbccExclusions', 
						@Priorities = N'$dbccPriorities', 
						@IncludeExtendedLogicalChecks = $dbccExtended, 
						@OperatorName = N'$dbccOperator', 
						@MailProfileName = N'$dbccProfile', 
						@EmailSubjectPrefix = N'$dbccSubject', 
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
				
				[string[]]$special = "NOTFOUND"; # various processing overrides/etc. 
				if ($special -contains $special) {
					return "<EMPTY>";
				}
				
				return $start;
			}
		}		
		
		# TODO: implement -IsDetailed definitions here. 
	}
}