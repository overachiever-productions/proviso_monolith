Set-StrictMode -Version 1.0;

<# 

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Assign -ProvisoRoot "\\storage\Lab\proviso\";
	Target "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1";

	Validate-ExtendedEvents;
	Summarize -Latest;

#>

Surface ExtendedEvents -Target "ExtendedEvents" {
	
	Assertions {
		
	}
	
	Aspect {
		#Facet "DisableXETelemetry"  {
		Facet "DisableXETelemetry" -Key "DisableTelemetry" {
			Expect {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$keyValue = $PVConfig.GetValue("ExtendedEvents.$instanceName.DisableTelemetry");
				$majorVersion = [int]$(Get-SqlServerInstanceMajorVersion -Instance $instanceName);
				
				if ($majorVersion -ge 13) {
					if ($keyValue) {
						return "<DISABLED>"; # vs $true which... is kind of confusing(ish) - i.e., 'state' the expectation or expected state here. 
					}
					
					return "<ENABLED>";
				}
				
				return "<N/A>";
			}
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$name = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "SELECT [name] FROM sys.[server_event_sessions] WHERE [name] = N'telemetry_xevents'; ").name;
				if ($name) {
					return "<ENABLED>";
				}
				
				$majorVersion = [int]$(Get-SqlServerInstanceMajorVersion -Instance $instanceName);
				if ($majorVersion -ge 13) {
					return "<DISABLED>";
				}
				
				return "<N/A>";
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				$expected = $PVContext.Expected;
				
				if ($expected) {
					Disable-TelemetryXEventsTrace -InstanceName $instanceName;
				}
				else {
					$PVContext.WriteLog("Config setting for [ExtendedVents.$sqlServerInstance.DisableTelemetry] is set to `$false - but SQL Telemetry has already been disabled and removed.. Proviso will NOT re-enable. Please make changes manually.", "Critical");
				}
			}
		}
		
		# TODO: Facets for XE creation. 
		# and... ideally, either: 
		#  		a. have an admindb sproc that creates XEs 
		# 		or ... 
		#  		b. have some scripts/templates/queries in Proviso somewhere that are used to create XEs. 
		# 		
		# 		option A makes the MOST sense ... but, there are concievable scenarios where people will use proviso but not the admindb. 
		#  		so... i think that option B makes the most sense... 
		#       	ALONG with the idea that I'll use those same (copy-pasted-ish - or  referenced ) definitions within an admindb sproc as well. 
	}
}