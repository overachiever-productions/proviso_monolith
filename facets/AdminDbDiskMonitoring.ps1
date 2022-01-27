﻿Set-StrictMode -Version 1.0;

Facet AdminDbDiskMonitoring {
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	# TODO: Disk monitoring Job is currently hard-coded to 'Regular Drive Space Checks'... 
	Group-Definitions -GroupKey "AdminDb.*" {
		Definition "DiskMonitoringEnabled" -ExpectValueForChildKey "DiskMonitoring.Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$state = Get-AgentJobStartTime -SqlServerInstanceName $instanceName -SqlServerAgentJob "Regular Drive Space Checks";
				
				if ($state -like "<*") {
					return $state;
				}
				
				return $true;
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				if ($expectedSetting) {
					
					[string]$GBsThreshold = $PVConfig.GetValue("AdminDb.$instanceName.DiskMonitoring.WarnWhenFreeGBsGoBelow");
					
					Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "EXEC [admindb].dbo.[enable_disk_monitoring]
						@WarnWhenFreeGBsGoBelow = $GBsThreshold, 
						@OverWriteExistingJob = 1; ";
					
				}
				else {
					$PVContext.WriteLog("Config setting for [Admindb.$instanceName.DiskMonitoring.Enabled] is set to `$false - but a Job Entitled 'Regular Drive Space Checks' already exists. Proviso will NOT drop this job. Please make changes manually.", "Critical");
				}
			}
		}
		
		Definition "WarnWhenGBsGoBelow" -ConfiguredBy "DiskMonitoringEnabled" {
			Expect {
				# TODO: look at implementing a param called something like -ExpectedValueFormat = "0:xxxx" or something like that so'z I can 
				#  use "32" treated as "32.0" or whatever, instead of having to create an 'explicit Expect {} block' like I've done here. 
				#  that said, notice how I also have to cast/format the TEST output as well - so this'll need a bit more work.
				#  	actually, it might just mean that there's a -Format for the Definition itself? and a -RemoveWhiteSpace switch for the Definition too? 
				
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedValue = $PVConfig.GetValue("AdminDb.$instanceName.DiskMonitoring.WarnWhenFreeGBsGoBelow");
				$double = [double]$expectedValue;
				
				return $double.ToString("###0.0");
			}
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$jobStepBody = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [command] FROM [msdb].dbo.[sysjobsteps] WHERE [step_name] = 'Check on Disk Space and Send Alerts' AND [job_id] = (SELECT [job_id] FROM [msdb].dbo.[sysjobs] WHERE [name] = N'Regular Drive Space Checks'); ").command;
				$regex = New-Object System.Text.RegularExpressions.Regex('WhenFreeGBsGoBelow = (?<gbs>[0-9|.]+)', [System.Text.RegularExpressions.RegexOptions]::Multiline);
				$matches = $regex.Match($jobStepBody);
				if ($matches) {
					$gbs = $matches.Groups[1].Value;
					
					$double = [double]$gbs;
					return $double.ToString("###0.0");
				}
			}
		}
	}
}