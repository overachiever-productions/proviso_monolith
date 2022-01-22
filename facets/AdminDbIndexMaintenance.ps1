Set-StrictMode -Version 1.0;

Facet AdminDbIndexMaintenance {
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	# TODO: currently using hard-coded job-names... 
	Group-Definitions -GroupKey "AdminDb.*" {
		Definition "IndexMaintenanceEnabled" -ExpectValueForChildKey "IndexMaintenance.Enabled" {
			Expect {
				$instanceName = $PVContext.CurrentKeyValue;
				
				# this one's a bit odd/goofy, we're either expecting true/false OR <WEEKDAY> OR <WEEKEND>
				$weekDayJobs, $weekendJobs = $false;
				if ($PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.DailyJobRunsOnDays")) {
					$weekDayJobs = $true;
				}
				if ($PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.WeekendJobRunsOnDays")) {
					$weekendJobs = $true;
				}
				
				if (($weekDayJobs) -and ($weekendJobs)) {
					return $true;
				}
				
				if (($weekDayJobs) -or ($weekendJobs)) {
					if ($weekDayJobs) {
						return "<WEEKDAY>";
					}
					
					return "<WEEKEND>";
				}
				
				return $false;
			}
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$weekDayJobs = Report-SqlServerAgentJobEnabledState -SqlServerAgentJob "Index Maintenance - WeekDay" -SqlServerInstanceName $instanceName;
				$weekendJobs = Report-SqlServerAgentJobEnabledState -SqlServerAgentJob "Index Maintenance - Weekend" -SqlServerInstanceName $instanceName;
				
				if (($weekDayJobs) -and ($weekendJobs)) {
					return $true;
				}
				
				if (($weekDayJobs) -or ($weekendJobs)) {
					if ($weekDayJobs) {
						return "<WEEKDAY>";
					}
					
					return "<WEEKEND>";
				}
				
				return $false;
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				if ($expectedSetting) {
					
					$weekDays = $PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.DailyJobRunsOnDays");
					$weekEnds = $PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.WeekendJobRunsOnDays");
					$ixJobStartTime = $PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.StartTime");
					$ixJobTimeZone = $PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.TimeZoneForUtcOffset");
					$ixJobPrefix = $PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.JobsNamePrefix");
					$ixJobCategory = $PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.JobsCategoryName");
					$ixJobOperator = $PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.OperatorToAlertOnErrors");
					
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
				else{
					$PVContext.WriteLog("Config setting for [Admindb.$instanceName.IndexMaintenance.Enabled] is set to `$false - but one or more Index Maintenance Jobs exist. Proviso will NOT drop these jobs. Please make changes manually.", "Critical");
				}
			}
		}
		
		Definition "DailyJobEnabled" -ConfiguredBy "IndexMaintenanceEnabled"{
			Expect {
				# TODO: create/define a switch called something like -RemoveAllWhiteSpace for the Definition class/object - which'll strip white-space from the expected key value.
				# 		then, i won't need this expect block. The RUB is ... the name of the switch will need to indicate that we're stripping ExpectedKeySpaces ... 
				#  	so, maybe: -StripExpectedKeyCharacters " " or something? 
				
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedDays = $PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.DailyJobRunsOnDays");
				
				return $expectedDays -replace " ", "";
			}
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$jobName = "Index Maintenance - WeekDay";
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
		
		Definition "WeekendJobEnabled" -ConfiguredBy "IndexMaintenanceEnabled"{
			Expect {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$expectedDays = $PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.WeekendJobRunsOnDays");
				
				return $expectedDays -replace " ", "";
			}
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$jobName = "Index Maintenance - Weekend";
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
		
		# TODO: Implement -IsDetailed Defintions here... 
	}
}