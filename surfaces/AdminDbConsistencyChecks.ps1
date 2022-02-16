Set-StrictMode -Version 1.0;

Surface AdminDbConsistencyChecks {
	
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	Aspect -Scope "AdminDb.*" {
		Facet "ConsistencyCheckJobEnabled" -ExpectChildKeyValue "ConsistencyChecks.Enabled" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$jobName = "Database Consistency Checks";
				$start = Get-AgentJobStartTime -SqlServerAgentJob $jobName -SqlServerInstanceName $instanceName;
				if ($start -like "<*") {
					return $start;
				}
				
				return $true;
			}
		}
		
		Facet "ConsistencyCheckDays" -UsesBuild {
			Expect {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedDays = $PVConfig.GetValue("AdminDb.$instanceName.ConsistencyChecks.ExecutionDays");
				
				return $expectedDays -replace " ", "";
			}
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$jobName = "Database Consistency Checks";
				return Get-AgentJobDaysSchedule -SqlServerAgentJob $jobName -SqlServerInstanceName $instanceName;
			}
		}
		
		Facet "Targets" -ExpectChildKeyValue "ConsistencyChecks.Targets" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$jobName = "Database Consistency Checks";
				$jobStepBody = Get-AgentJobStepBody -SqlServerAgentJob $jobName -JobStepName "Check Database Consistency" -SqlServerInstanceName $instanceName;
				if ($jobStepBody -like "<*") {
					return $jobStepBody;
				}
				
				$regex = New-Object System.Text.RegularExpressions.Regex("@Targets = N'(?<targets>[^']+)", [System.Text.RegularExpressions.RegexOptions]::Multiline);
				$matches = $regex.Match($jobStepBody);
				if ($matches) {
					$targets = $matches.Groups[1].Value;
					
					return $targets;
				}
			}
		}
		
		Facet "StartTime" -ExpectChildKeyValue "ConsistencyChecks.StartTime" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$jobName = "Database Consistency Checks";
				return Get-AgentJobStartTime -SqlServerAgentJob $jobName -SqlServerInstanceName $instanceName;
			}
		}
		
		Build {
			$sqlServerInstance = $PVContext.CurrentKeyValue;
			$facetName = $PVContext.CurrentFacetName;
			$matched = $PVContext.Matched;
			$expected = $PVContext.Expected;
			
			if ($false -eq $expected) {
				switch ($facetName) {
					"ConsistencyCheckJobEnabled" {
						$jobName = $PVConfig.GetValue("AdminDb.$sqlServerInstance.ConsistencyChecks.JobName");
						$PVContext.WriteLog("Config setting for [Admindb.$sqlServerInstance.ConsistencyChecks.Enabled] is set to `$false - but a job entitled [$jobName] already exists. Proviso will NOT drop this job. Please make changes manually.", "Critical");
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
		}
		
		# TODO: implement -Detailed facets here. 
	}
}