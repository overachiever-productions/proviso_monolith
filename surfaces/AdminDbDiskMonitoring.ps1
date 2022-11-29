Set-StrictMode -Version 1.0;

Surface AdminDbDiskMonitoring -Target "AdminDb" {
	Assertions {
		Assert-SqlServerIsInstalled -ConfigureOnly;
		Assert-AdminDbInstalled -ConfigureOnly;
	}
	
	# TODO: Disk monitoring Job is currently hard-coded to 'Regular Drive Space Checks'... 
	Aspect -Scope "DiskMonitoring" {
		Facet "DiskMonitoringEnabled" -Key "Enabled" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$state = Get-AgentJobStartTime -SqlServerInstanceName $instanceName -SqlServerAgentJob "Regular Drive Space Checks";				
				if ($state -like "<*") {
					return $state;
				}
				
				return $true;
			}
		}
		
		Facet "WarnWhenGBsGoBelow" -Key "WarnWhenFreeGBsGoBelow" -UsesBuild {
			Expect {
				# TODO: look at implementing a param called something like -ExpectedValueFormat = "0:xxxx" or something like that so'z I can 
				#  use "32" treated as "32.0" or whatever, instead of having to create an 'explicit Expect {} block' like I've done here. 
				#  that said, notice how I also have to cast/format the TEST output as well - so this'll need a bit more work.
				#  	actually, it might just mean that there's a -Format for the Facet itself? and a -RemoveWhiteSpace switch for the Scope too? 
				$expectedValue = $PVContext.CurrentConfigKeyValue;
				$double = [double]$expectedValue;
				
				return $double.ToString("###0.0");
			}
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$expectedSetting = $PVContext.CurrentConfigKeyValue;				
				$jobStepBody = Get-AgentJobStepBody -SqlServerAgentJob "Regular Drive Space Checks" -JobStepName "Check on Disk Space and Send Alerts" -SqlServerInstanceName $instanceName;
				if ($jobStepBody -like "<*") {
					return $jobStepBody;
				}
				
				$regex = New-Object System.Text.RegularExpressions.Regex('WhenFreeGBsGoBelow = (?<gbs>[0-9|.]+)', [System.Text.RegularExpressions.RegexOptions]::Multiline);
				$matches = $regex.Match($jobStepBody);
				if ($matches) {
					$gbs = $matches.Groups[1].Value;
					
					$double = [double]$gbs;
					return $double.ToString("###0.0");
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
					"DiskMonitoringEnabled" {
						#$jobName = $PVConfig.GetValue("AdminDb.$sqlServerInstance.DiskMonitoring.JobName");
						$PVContext.WriteLog("Config setting for [Admindb.$sqlServerInstance.DiskMonitoring.Enabled] is set to `$false - but a Disk Monitoring job already exists. Proviso will NOT drop this job. Please make changes manually.", "Critical");
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
				[string]$GBsThreshold = $PVConfig.GetValue("AdminDb.$instanceName.DiskMonitoring.WarnWhenFreeGBsGoBelow");
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "EXEC [admindb].dbo.[enable_disk_monitoring]
						@WarnWhenFreeGBsGoBelow = $GBsThreshold, 
						@OverWriteExistingJob = 1; ";
			}
		}
	}
}