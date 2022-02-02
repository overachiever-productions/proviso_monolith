Set-StrictMode -Version 1.0;

Surface AdminDbAlerts {
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	Aspect -Scope "AdminDb.*" {
		Facet "IOAlertsEnabled" -ExpectChildKeyValue "Alerts.IOAlertsEnabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
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
				
				$PVContext.AddSurfaceState("$instanceName.IoAlertsEnabled", $true);
				return $true;
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				
				# Expected Values:
				$ioAlertsEnabled = $PVConfig.GetValue("AdminDb.$instanceName.Alerts.IOAlertsEnabled");
				$severityAlertsEnabled = $PVConfig.GetValue("AdminDb.$instanceName.Alerts.SeverityAlertsEnabled");
				$ioAlertsFiltered = $PVConfig.GetValue("AdminDb.$instanceName.Alerts.IOAlertsFiltered");
				$severityAlertsFiltered = $PVConfig.GetValue("AdminDb.$instanceName.Alerts.SeverityAlertsFiltered");
				
				# this is a bit ugly (these next 4x checks)
				if ($PVContext.GetSurfaceState("$instanceName.IoAlertsEnabled") -and (-not ($ioAlertsEnabled))) {
					$PVContext.WriteLog("Config setting for [Admindb.$instanceName.Alerts.IOAlertsEnabled] is set to `$false - but 4x alerts for IO problems already exist. Proviso will NOT remove these 4x alerts (605, 823, 824, 825). Please make changes manually.", "Critical");
				}
				if ($PVContext.GetSurfaceState("$instanceName.SeverityAlertsEnabled") -and (-not ($severityAlertsEnabled))) {
					$PVContext.WriteLog("Config setting for [Admindb.$instanceName.Alerts.SeverityAlertsEnabled] is set to `$false - but Severity alerts already exist. Proviso will NOT remove Severity alerts. Please make changes manually.", "Critical");
				}
				if ($PVContext.GetSurfaceState("$instanceName.IOAlertsFiltered") -and (-not ($ioAlertsFiltered))) {
					$PVContext.WriteLog("Config setting for [Admindb.$instanceName.Alerts.IOAlertsFiltered] is set to `$false - but IO Alert Filtering ALREADY exists. Proviso will NOT remove Alert Filtering. Please make changes manually.", "Critical");
				}
				if ($PVContext.GetSurfaceState("$instanceName.SeverityAlertsFiltered") -and (-not ($severityAlertsFiltered))) {
					$PVContext.WriteLog("Config setting for [Admindb.$instanceName.Alerts.SeverityAlertsFiltered] is set to `$false - but Severity Alert Filtering ALREADY exists. Proviso will NOT remove Alert Filtering. Please make changes manually.", "Critical");
				}
				
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
		
		Facet "SeverityAlertsEnabled" -ExpectChildKeyValue "Alerts.SeverityAlertsEnabled" -ConfiguredBy "IOAlertsEnabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
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
				
				$PVContext.AddSurfaceState("$instanceName.SeverityAlertsEnabled", $true);
				return $true;
			}
		}
		
		Facet "IOAlertsFiltered" -ExpectChildKeyValue "Alerts.IOAlertsFiltered" -ConfiguredBy "IOAlertsEnabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$count = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT COUNT([job_id]) [count] FROM msdb.[dbo].[sysalerts] WHERE [message_id] IN (605, 823, 824, 825) AND [enabled] = 1 AND [job_id] <> '00000000-0000-0000-0000-000000000000'; ").count;
				if ($count -eq 0){
					return $false;
				}
				
				$PVContext.AddSurfaceState("$instanceName.IOAlertsFiltered", $true);
				if ($count -eq 4){
					return $true;
				}
				
				return "<MIXED>";
			}
		}
		
		Facet "SeverityAlertsFiltered" -ExpectChildKeyValue "Alerts.SeverityAlertsFiltered" -ConfiguredBy "IOAlertsEnabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$count = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT COUNT(job_id) [count] FROM [msdb].dbo.[sysalerts] WHERE [severity] >= 17 AND [enabled] = 1 AND [job_id] <> '00000000-0000-0000-0000-000000000000' ").count;
				if ($count -eq 0) {
					return $false;
				}
				
				$PVContext.AddSurfaceState("$instanceName.SeverityAlertsFiltered", $true);
				if ($count -eq 9) {
					return $true;
				}
				
				return "<MIXED>";
			}
		}
	}
}