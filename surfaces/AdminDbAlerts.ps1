Set-StrictMode -Version 1.0;

Surface AdminDbAlerts -Target "AdminDb" {
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	Aspect -Scope "Alerts" {
		#Facet "IOAlertsEnabled" -ExpectChildKeyValue "Alerts.IOAlertsEnabled" -UsesBuild {
		Facet "IOAlertsEnabled" -Key "IOAlertsEnabled" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				[int[]]$expected = 605, 823, 824, 825;
				$alerts = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [message_id] FROM msdb.[dbo].[sysalerts] WHERE [message_id] IN (605, 823, 824, 825) AND [enabled] = 1; ").message_id;
				
				$missing = "";
				foreach ($id in $expected) {
					if ($alerts -notcontains $id) {
						$missing += "$id, ";
					}
				}
				
				if ($missing) {
					$missing = $missing.Substring(0, $missing.length - 2);
					$PVContext.WriteLog("IO Alerts on Instance [$instanceName] is missing $missing (which may be present but DISABLED).", "Verbose");
					return $false;
				}
				
				return $true;
			}
		}
		
		#Facet "SeverityAlertsEnabled" -ExpectChildKeyValue "Alerts.SeverityAlertsEnabled" -UsesBuild {
		Facet "SeverityAlertsEnabled" -Key "SeverityAlertsEnabled" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				[int[]]$expected = 17 .. 25;
				$severities = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [severity] FROM [msdb].dbo.[sysalerts] WHERE [severity] >= 17 AND [enabled] = 1; ").severity;
				
				$missing = "";
				foreach ($id in $expected) {
					if ($severities -notcontains $id) {
						$missing += "$id, ";
					}
				}
				
				if ($missing) {
					$missing = $missing.Substring(0, $missing.length - 2);
					$PVContext.WriteLog("Severity Alerts on Instance [$instanceName] is missing severities $missing. (They may be present - but DISABLED.)", "Verbose");
					return $false;
				}
				
				return $true;
			}
		}
		
		#Facet "IOAlertsFiltered" -ExpectChildKeyValue "Alerts.IOAlertsFiltered" -UsesBuild {
		Facet "IOAlertsFiltered" -Key "IOAlertsFiltered" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$count = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT COUNT([job_id]) [count] FROM msdb.[dbo].[sysalerts] WHERE [message_id] IN (605, 823, 824, 825) AND [enabled] = 1 AND [job_id] <> '00000000-0000-0000-0000-000000000000'; ").count;
				if ($count -eq 0){
					return $false;
				}
				
				if ($count -eq 4){
					return $true;
				}
				
				return "<MIXED>";
			}
		}
		
		#Facet "SeverityAlertsFiltered" -ExpectChildKeyValue "Alerts.SeverityAlertsFiltered" -UsesBuild {
		Facet "SeverityAlertsFiltered" -Key "SeverityAlertsFiltered" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$count = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT COUNT(job_id) [count] FROM [msdb].dbo.[sysalerts] WHERE [severity] >= 17 AND [enabled] = 1 AND [job_id] <> '00000000-0000-0000-0000-000000000000' ").count;
				if ($count -eq 0) {
					return $false;
				}
				
				if ($count -eq 9) {
					return $true;
				}
				
				return "<MIXED>";
			}
		}
		
		Build {
			$sqlServerInstance = $PVContext.CurrentSqlInstance;
			$matched = $PVContext.Matched;
			$expected = $PVContext.Expected;
			
			if ($false -eq $expected) {
				switch ($facetName) {
					"IOAlertsEnabled" {
						$PVContext.WriteLog("Config setting for [Admindb.$sqlServerInstance.Alerts.IOAlertsEnabled] is set to `$false - but 4x alerts for IO problems already exist. Proviso will NOT remove these 4x alerts (605, 823, 824, 825). Please make changes manually.", "Critical");
						return; # don't redo the deploy... it WON'T remove these alerts... so no sense in running it.
					}
					"SeverityAlertsEnabled" {
						$PVContext.WriteLog("Config setting for [Admindb.$sqlServerInstance.Alerts.SeverityAlertsEnabled] is set to `$false - but Severity alerts already exist. Proviso will NOT remove Severity alerts. Please make changes manually.", "Critical");
						return; # don't redo the deploy... it WON'T remove these alerts... so no sense in running it.
					}
					# TODO: verify that setting filters OFF will... turn them off (via reconfig)
#					"IOAlertsFiltered" {
#						$PVContext.WriteLog("Config setting for [Admindb.$sqlServerInstance.Alerts.IOAlertsFiltered] is set to `$false - but IO Alert Filtering ALREADY exists. Proviso will NOT remove Alert Filtering. Please make changes manually.", "Critical");
#					}
#					"SeverityAlertsFiltered" {
#						$PVContext.WriteLog("Config setting for [Admindb.$sqlServerInstance.Alerts.SeverityAlertsFiltered] is set to `$false - but Severity Alert Filtering ALREADY exists. Proviso will NOT remove Alert Filtering. Please make changes manually.", "Critical");
#					}
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
				
				# Expected Values:
				$ioAlertsEnabled = $PVConfig.GetValue("AdminDb.$instanceName.Alerts.IOAlertsEnabled");
				$severityAlertsEnabled = $PVConfig.GetValue("AdminDb.$instanceName.Alerts.SeverityAlertsEnabled");
				$ioAlertsFiltered = $PVConfig.GetValue("AdminDb.$instanceName.Alerts.IOAlertsFiltered");
				$severityAlertsFiltered = $PVConfig.GetValue("AdminDb.$instanceName.Alerts.SeverityAlertsFiltered");
				
				# Alerts:
				$alertTypes = "";
				if (($ioAlertsEnabled) -and ($severityAlertsEnabled)) {
					$alertTypes = "SEVERITY_AND_IO";
				}
				else {
					if ($ioAlertsEnabled) {
						$alertTypes = "IO";
					}
					else {
						$alertTypes = "SEVERITY";
					}
				}
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "EXEC [admindb].dbo.[enable_alerts] 
					@AlertTypes = N'$alertTypes'; ";
				
				# Filters:				
				$alertFilters = "";
				if (($ioAlertsFiltered) -and ($severityAlertsFiltered)) {
					$alertFilters = "SEVERITY_AND_IO";
				}
				else {
					if ($ioAlertsFiltered) {
						$alertFilters = "IO";
					}
					else {
						$alertFilters = "SEVERITY";
					}
				}
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "EXEC admindb.dbo.[enable_alert_filtering]
					@TargetAlerts = N'$alertFilters'; ";
			}
		}
	}
}