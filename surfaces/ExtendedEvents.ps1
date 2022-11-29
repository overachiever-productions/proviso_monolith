﻿Set-StrictMode -Version 1.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Assign -ProvisoRoot "\\storage\Lab\proviso\";
	Target "\\storage\lab\proviso\definitions\PRO\PRO-197.psd1" -Strict:$false;

	#$PVResources.GetXeSessionDefinitionFile("blocked_processes.sql");

	Validate-ExtendedEvents;

#>


Surface ExtendedEvents -Target "ExtendedEvents" {
	
	Assertions {
		
	}
	
	Aspect {
		Facet "DisableXETelemetry" -Key "DisableTelemetry" {
			Expect {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$keyValue = $PVConfig.GetValue($PVContext.CurrentConfigKey);
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
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$name = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "SELECT [name] FROM sys.[dm_xe_sessions] WHERE [name] = N'telemetry_xevents'; ").name;
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
				$instanceName = $PVContext.CurrentSqlInstance;
				$expected = $PVContext.Expected;
				
				if ($expected) {
					Disable-TelemetryXEventsTrace -InstanceName $instanceName;
				}
				else {
					$PVContext.WriteLog("Config setting for [ExtendedVents.$sqlServerInstance.DisableTelemetry] is set to `$false - but SQL Telemetry has already been disabled and removed. Proviso will NOT re-enable. Please make changes manually.", "Critical");
				}
			}
		}
	}
	
	Aspect -IterateForScope "Sessions" {
		Facet "Exists" -Key "SessionName" -Expect $true {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
#				$sessionKey = $PVContext.CurrentObjectName;				
#				$sessionName = $PVConfig.GetValue("ExtendedEvents.$instanceName.Sessions.$sessionKey.SessionName");			
				$sessionName = $PVContext.CurrentConfigKeyValue;
				$exists = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "SELECT [name] FROM sys.[server_event_sessions] WHERE [name] = N'$sessionName'; ").name;
				if ($exists) {
					return $true;
				}
				
				return $false;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$sessionKey = $PVContext.CurrentObjectName;
				
				$definitionFile = $PVConfig.GetValue("ExtendedEvents.$instanceName.Sessions.$sessionKey.DefinitionFile");
				
				# TODO: determine if we're in a DROP or CREATE scenario and warn/announce that PROVISO won't drop existing XeSessions... 
				#  	that said, I PRESUME there's a case where this might exist or not? or, is Configure ONLY EVER going to be called if/when we EXPECT an XE session and it doesn't exist?
				
				$fullDefinitionPath = $PVResources.GetXeSessionDefinitionFile($definitionFile);
				if ($null -eq $fullDefinitionPath) {
					throw "Invalid XE Session Configuration Settings. Unable to locate XE Session Definition file [$definitionFile].";
				}
				
				$template = Get-Content $fullDefinitionPath;
							
				$sessionName = $PVConfig.GetValue("ExtendedEvents.$instanceName.Sessions.$sessionKey.SessionName");
				$enabled = $PVConfig.GetValue("ExtendedEvents.$instanceName.Sessions.$sessionKey.Enabled");
				$startWithSystem = $PVConfig.GetValue("ExtendedEvents.$instanceName.Sessions.$sessionKey.StartWithSystem");
				$fileSize = $PVConfig.GetValue("ExtendedEvents.$instanceName.Sessions.$sessionKey.XelFileSizeMb");
				$fileCount = $PVConfig.GetValue("ExtendedEvents.$instanceName.Sessions.$sessionKey.XelFileCount");
				$xelFilePath = $PVConfig.GetValue("ExtendedEvents.$instanceName.Sessions.$sessionKey.XelFilePath");
				$defaultXelFilePath = $PVConfig.GetValue("ExtendedEvents.$instanceName.DefaultXelDirectory");
				
				if ([string]::IsNullOrEmpty($xelFilePath)) {
					$xelFilePath = $defaultXelFilePath;
				}
				
				$startupState = "OFF";
				$isEnabled = "OFF";
				if ($startWithSystem) {
					$startupState = "ON";
				}
				if ($enabled) {
					$isEnabled = "ON";
				}
				
				[string]$xeBody = $template -replace "{sessionName}", $sessionName;
				$xeBody = $xeBody -replace "{storagePath}", $xelFilePath;
				$xeBody = $xeBody -replace "{maxFileSize}", $fileSize;
				$xeBody = $xeBody -replace "{maxFiles}", $fileCount;
				$xeBody = $xeBody -replace "{startupState}", $startupState;
				$xeBody = $xeBody -replace "{isEnabled}", $isEnabled;
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query $xeBody;
			}
		}
		
		Facet "Enabled" -Key "Enabled" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$sessionKey = $PVContext.CurrentObjectName;				
				$sessionName = $PVConfig.GetValue("ExtendedEvents.$instanceName.Sessions.$sessionKey.SessionName");				
				$state = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "SELECT [name] FROM sys.[dm_xe_sessions] WHERE [name] = N'$sessionName'; ").name;
				if ($state) {
					return $true;
				}
				
				return $false;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$sessionKey = $PVContext.CurrentObjectName;
				
				$sessionName = $PVConfig.GetValue("ExtendedEvents.$instanceName.Sessions.$sessionKey.SessionName");
				$desiredState = $PVContext.CurrentConfigKeyValue;
				$desiredStateString = "START";
				if (-not ($desiredState)) {
					$desiredStateString = "STOP";
					
					$PVContext.WriteLog("WARNING: Extended Events Session [$sessionName] has been DISABLED.", "Important");
				}
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "ALTER EVENT SESSION [$sessionName] ON SERVER STATE = $desiredStateString; ";
			}
		}
		
		Facet "StartWithSystem" -Key "StartWithSystem" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$sessionKey = $PVContext.CurrentObjectName;				
				$sessionName = $PVConfig.GetValue("ExtendedEvents.$instanceName.Sessions.$sessionKey.SessionName");
				
				$startState = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "SELECT startup_state FROM sys.[server_event_sessions] WHERE [name] = N'$sessionName';").startup_state;
				if ($startState) {
					return $true;
				}
				
				return $false;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$sessionKey = $PVContext.CurrentObjectName;
				
				$sessionName = $PVConfig.GetValue("ExtendedEvents.$instanceName.Sessions.$sessionKey.SessionName");
				
				$desiredState = $PVContext.CurrentConfigKeyValue;
				$desiredStateString = "ON";
				if (-not($desiredState)) {
					$desiredStateString = "OFF";
					
					# TODO: need to see what the CURRENT value is - it MIGHT be OFF/disabled. (though, in which case, why is this... trying to make a change? )
					$PVContext.WriteLog("WARNING: Auto-Start for Extended Events Session [$sessionName] has been DISABLED.", "Important");
				}
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "ALTER EVENT SESSION [$sessionName] ON SERVER WITH (STARTUP_STATE = $desiredStateString); ";
			}
		}
		
		# TODO: treat remaining values like XelFileSize, XelCount, XelPath as advanced options.
	}
}