Set-StrictMode -Version 1.0;

Surface AGsCore -Target "AvailabilityGroups" {
	Assertions {
		
	}
	
	Aspect {
		Facet "AGCapabilitiesEnabled" -Key "Enabled" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$result = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "SELECT SERVERPROPERTY('IsHadrEnabled') [result];").result;
				if ($result -eq 0) {
					return "<DISABLED>";
				}
				else {
					return $true;
				}
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$expectedValue = $PVConfig.GetValue("AvailabilityGroups.$instanceName.Enabled");
				if ($expectedValue) {
					
					Enable-AlwaysOnAccessForSqlServerInstance -SQLInstance $instanceName
					
					$PVContext.SetSqlRestartRequired("AlwaysOn Requires Restart of SQL Server to enable access to WSFC Cluster.");
				}
				else {
					$PVContext.WriteLog("Proviso will NOT disable AG functionality. This needs to be done manually.", "Critical");
				}
			}
		}
		
		Facet "AlwaysOnXeHealthEnabled" -Key "AlwaysOnXeHealthEnabled" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$state = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "SELECT [startup_state] FROM sys.server_event_sessions WHERE name='AlwaysOn_health';").startup_state;
				if ($state -or (0 -eq $state)) {
					$PVContext.SetSurfaceState("$instanceName.AG_XE_Health_Exists", $true);
					
					if (1 -eq $state) {
						return $true;
					}
					
					return "<OFF>";
				}
				else {
					$PVContext.SetSurfaceState("$instanceName.AG_XE_Health_Exists", $false);
					return ""; # empty/not-found... 
				}
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$expected = $PVContext.CurrentConfigKeyValue;
				
				if (-not ($PVContext.GetSurfaceState("$instanceName.AG_XE_Health_Exists"))) {
						
					# NOTE: this is just a right-click + script + copy/paste/minor-tweak (remove GO and add a ';') from an existing definition on a server. 	
					$command = "CREATE EVENT SESSION [AlwaysOn_health] ON SERVER 
ADD EVENT sqlserver.alwayson_ddl_executed,
ADD EVENT sqlserver.availability_group_lease_expired,
ADD EVENT sqlserver.availability_replica_automatic_failover_validation,
ADD EVENT sqlserver.availability_replica_manager_state_change,
ADD EVENT sqlserver.availability_replica_state,
ADD EVENT sqlserver.availability_replica_state_change,
ADD EVENT sqlserver.error_reported(
    WHERE ([error_number]=(9691) OR [error_number]=(35204) OR [error_number]=(9693) OR [error_number]=(26024) OR [error_number]=(28047) OR [error_number]=(26023) OR [error_number]=(9692) OR [error_number]=(28034) OR [error_number]=(28036) OR [error_number]=(28048) OR [error_number]=(28080) OR [error_number]=(28091) OR [error_number]=(26022) OR [error_number]=(9642) OR [error_number]=(35201) OR [error_number]=(35202) OR [error_number]=(35206) OR [error_number]=(35207) OR [error_number]=(26069) OR [error_number]=(26070) OR [error_number]>(41047) AND [error_number]<(41056) OR [error_number]=(41142) OR [error_number]=(41144) OR [error_number]=(1480) OR [error_number]=(823) OR [error_number]=(824) OR [error_number]=(829) OR [error_number]=(35264) OR [error_number]=(35265) OR [error_number]=(41188) OR [error_number]=(41189) OR [error_number]=(35217))),
ADD EVENT sqlserver.hadr_db_partner_set_sync_state,
ADD EVENT sqlserver.hadr_trace_message,
ADD EVENT sqlserver.lock_redo_blocked,
ADD EVENT sqlserver.sp_server_diagnostics_component_result(SET collect_data=(1)
    WHERE ([state]=(3))),
ADD EVENT ucs.ucs_connection_setup
ADD TARGET package0.event_file(SET filename=N'AlwaysOn_health.xel',max_file_size=(100),max_rollover_files=(10))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF); ";
					
					Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query $command;
				}
				
				# otherwise: 
				$startupState = "OFF";
				$currentState = "STOP";
				
				if ($expected) {
					$startupState = "ON";
					$currentState = "START";
				}
				
				$command = "ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE = $startupState);";
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query $command;
				
				$command = "IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health') ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE = $currentState;";
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query $command;
			}
		}
	}
	
	Aspect -Scope "MirroringEndpoint" {
		Facet "Endpoint Exists" -Key "Name" -ExpectKeyValue -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				$endpointName = $PVConfig.GetValue("AvailabilityGroups.$instanceName.MirroringEndpoint.Name");
				
				$sqlName = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "SELECT [name] FROM sys.tcp_endpoints WHERE [type] = 4 AND [name] = N'$endpointName';").name;
				if ($sqlName) {
					$PVContext.SetSurfaceState("$instanceName.EndpointEnabled", $true);
					return $sqlName;
				}
				
				$PVContext.SetSurfaceState("$instanceName.EndpointEnabled", $false);
				return "";
			}
		}
		
		Facet "Endpoint Enabled" -Key "Enabled" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.EndpointEnabled"))) {
					return "";
				}
				
				$endpointName = $PVConfig.GetValue("AvailabilityGroups.$instanceName.MirroringEndpoint.Name");
				
				$state = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "SELECT [state_desc] FROM sys.[endpoints] WHERE [name] = N'$endpointName';").state_desc;
				if ($state) {
					if ("STARTED" -eq $state) {
						return $true;
					}
					
					return "<$state>";  # stopped or disabled... 
				}
				
				return "";
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$endpointName = $PVConfig.GetValue("AvailabilityGroups.$instanceName.MirroringEndpoint.Name");
				
				$query = "ALTER ENDPOINT [$endPointName] STATE = STARTED; ";
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query $query;
			}
		}
		
		Facet "PortNumber" -Key "PortNumber" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.EndpointEnabled"))) {
					return "";
				}
				
				$endpointName = $PVConfig.GetValue("AvailabilityGroups.$instanceName.MirroringEndpoint.Name");
				
				$portNumber = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "SELECT [port] FROM sys.tcp_endpoints WHERE [type] = 4 AND [name] = N'$endpointName';").port;
				
				return $portNumber;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$endpointName = $PVConfig.GetValue("AvailabilityGroups.$instanceName.MirroringEndpoint.Name");
				$portNumber = $PVContext.CurrentConfigKeyValue;
				
				# TODO: How does this impact things (operations and/or even JUST the ability to SET this value) IF/WHEN the endpoint is enabled? 
				# 		i.e., I've tested this in scenarios where the endpoint was STOPPED. Do I need to do more? And, obviously, this'll cause some sort of 
				# 		HICCUP (best case) in secenarios where we're changing this value... 
				# 		as in, ARGUABLY, it might not make sense to LET Proviso CHANGE this value? 
				$query = "ALTER ENDPOINT [$endpointName] AS TCP (LISTENER_PORT = $portNumber);";
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query $query;
			}
		}
		
		Facet "Endpoint Owner" -Key "EndpointOwner" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.EndpointEnabled"))) {
					return "";
				}
				
				$endpointName = $PVConfig.GetValue("AvailabilityGroups.$instanceName.MirroringEndpoint.Name");
				
				$owner = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "SELECT [p].[name] FROM sys.[endpoints] [e] INNER JOIN sys.[server_principals] [p] ON [e].[principal_id] = [p].[principal_id] WHERE [e].[name] = N'$endpointName';").name;
				
				return $owner;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$endpointName = $PVConfig.GetValue("AvailabilityGroups.$instanceName.MirroringEndpoint.Name");
				
				$targetOwner = $PVContext.CurrentConfigKeyValue;
				
				$query = "ALTER AUTHORIZATION ON ENDPOINT::[$endpointName] TO [$targetOwner];";
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query $query;
			}
		}
		
		Facet "GrantConnectTo" -Key "GrantConnect" -Expect $true {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.EndpointEnabled"))) {
					return "";
				}
				
				$endpointName = $PVConfig.GetValue("AvailabilityGroups.$instanceName.MirroringEndpoint.Name");
				$expectedConnector = $PVContext.CurrentConfigKeyValue;
				
				$query = "SELECT 
					p.[permission_name]
				FROM 
					sys.[endpoints] e 
					INNER JOIN sys.[server_permissions] p ON e.[endpoint_id] = p.[major_id]
					INNER JOIN sys.[server_principals] s ON p.[grantee_principal_id] = s.[principal_id]
				WHERE 
					e.[name] = N'$endpointName'
					AND s.[name] = N'$expectedConnector'
					AND p.[permission_name] = N'CONNECT';";
				
				$exists = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query $query).permission_name;
				if ($exists -and ("CONNECT" -eq $exists)) {
					return $true;
				}

				return $exists;
			}
			Configure {
				# Note, there's currently no 'concept' of removing access via Proviso (i.e., don't even NEED to check for removes) - as in: each entry that hits configure is just looking to GRANT
				$instanceName = $PVContext.CurrentSqlInstance;
				$endpointName = $PVConfig.GetValue("AvailabilityGroups.$instanceName.MirroringEndpoint.Name");
				$expectedConnector = $PVContext.CurrentConfigKeyValue;
				
				$query = "GRANT CONNECT ON ENDPOINT::[$endpointName] TO [$expectedConnector];";
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query $query;
			}
		}
	}
	
#	Aspect -Scope "SynchronizationChecks" {
#		
#	}
	
	Build {
		$instanceName = $PVContext.CurrentSqlInstance;
		
		if ("Endpoint Exists" -eq $PVContext.CurrentFacetName) {
			if (-not ($PVContext.Matched)) {
				if ($PVContext.Expected) {
					$targetInstances = $PVContext.GetSurfaceState("TargetInstances");
					if ($null -eq $targetInstances) {
						$targetInstances = @();
					}
					
					if ($targetInstances -notcontains $instanceName) {
						$targetInstances += $instanceName
					}
					
					$PVContext.SetSurfaceState("TargetInstances", $targetInstances);
				}
				else {
					$endpointName = $PVConfig.GetValue("AvailabilityGroups.$instanceName.MirroringEndpoint.Name");
					
					$PVContext.WriteLog("SQL Server Endpoint [$endpointName] already exists - but config expects it to be disabled/non-extant. Proviso will NOT remove this endpoint. It must be done manually.", "Critical");
				}
			}
		}
	}
	
	Deploy {
		foreach ($instanceName in @($PVContext.GetSurfaceState("TargetInstances"))) {
			
			$endPointName = $PVConfig.GetValue("AvailabilityGroups.$instanceName.MirroringEndpoint.Name");
			$portNumber = $PVConfig.GetValue("AvailabilityGroups.$instanceName.MirroringEndpoint.PortNumber");
			$encType = $PVConfig.GetValue("AvailabilityGroups.$instanceName.MirroringEndpoint.EncryptionAlgorithm");
			
			# TODO: add details/options for authorization types, certs, etc. 
			
			$query = "CREATE ENDPOINT [$endPointName] AS TCP (LISTENER_PORT = $portNumber) FOR DATA_MIRRORING (ROLE = ALL, ENCRYPTION = REQUIRED ALGORITHM $encType);"
			Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query $query;
		}
	}
}