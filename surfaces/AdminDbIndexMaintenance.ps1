Set-StrictMode -Version 1.0;

Surface AdminDbIndexMaintenance {
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	# TODO: currently using hard-coded job-names... 
	Aspect -Scope "AdminDb.*" {
		Facet "IndexMaintenanceEnabled" -UsesBuild {
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
				
				$weekDayStart = Get-AgentJobStartTime -SqlServerAgentJob "Index Maintenance - WeekDay" -SqlServerInstanceName $instanceName;
				$weekendStart = Get-AgentJobStartTime -SqlServerAgentJob "Index Maintenance - Weekend" -SqlServerInstanceName $instanceName;
				
				$weekDayJobs = $weekendJobs = $false;
				if ($weekDayStart -notlike "<*") {
					$weekDayJobs = $true;
				}
				if ($weekendStart -notlike "<*") {
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
		}
		
		Facet "IXMaintCodeDeployed" -For "Confirming that Ola Hallengren's Scripts are available if/as needed." {
			Expect {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$ixMaintExpected = $PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.Enabled");
				if ($ixMaintExpected) {
					return $true;
				}
			}
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$count = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "SELECT COUNT(*) [count] FROM master.sys.[objects] WHERE [name] IN (N'CommandLog', N'CommandExecute', N'IndexOptimize'); ").count;
				if ($count -eq 3) {
					return $true;
				}
				
				if ($count -gt 0) {
					return "<MIXED>";
				}
				
				return $false;
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$scriptPath = $PVResources.GetAsset("hallengren_ix_optimize_only", "sql");
				if (-not (Test-Path $scriptPath)) {
					throw "Unable to locate asset [hallengren_ix_optimize_only.sql] at expected location of: [$scriptPath].";
				}
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -InputFile $scriptPath -DisableVariables;
			}
		}
		
		Facet "DailyJobEnabled" -UsesBuild{
			Expect {
				# TODO: create/define a switch called something like -RemoveAllWhiteSpace for the Facet class/object - which'll strip white-space from the expected key value.
				# 		then, i won't need this expect block. The RUB is ... the name of the switch will need to indicate that we're stripping ExpectedKeySpaces ... 
				#  	so, maybe: -StripExpectedKeyCharacters " " or something? 
				
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedDays = $PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.DailyJobRunsOnDays");
				
				return $expectedDays -replace " ", "";
			}
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$jobName = "Index Maintenance - WeekDay";
				return Get-AgentJobDaysSchedule -SqlServerAgentJob $jobName -SqlServerInstanceName $instanceName;
			}
		}
		
		Facet "WeekendJobEnabled" -UsesBuild{
			Expect {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$expectedDays = $PVConfig.GetValue("AdminDb.$instanceName.IndexMaintenance.WeekendJobRunsOnDays");
				
				return $expectedDays -replace " ", "";
			}
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$jobName = "Index Maintenance - Weekend";
				return Get-AgentJobDaysSchedule -SqlServerAgentJob $jobName -SqlServerInstanceName $instanceName;
			}
		}
		
		# TODO: Implement -Detailed Facets here... 
		
		Build {
			$sqlServerInstance = $PVContext.CurrentKeyValue;
			$matched = $PVContext.Matched;
			
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
		}
	}
}