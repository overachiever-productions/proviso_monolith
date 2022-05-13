Set-StrictMode -Version 1.0;

<#
	
	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Map -ProvisoRoot "\\storage\Lab\proviso\";
	#Target -ConfigFile "\\storage\lab\proviso\definitions\MeM\mempdb1b.psd1" -Strict:$false;
	Target -ConfigFile "\\storage\lab\proviso\definitions\PRO\PRO-197.psd1" -Strict:$false;

	$PVConfig.GetSqlInstanceNames("AdminDb");


#	Is-ValidProvisoKey -Key "SqlServerConfiguration.DisableSaLogin";
#	Is-ValidProvisoKey -Key "SqlServerConfiguration.DeployContingencySpace";
#
#	$PVConfig.GetSqlInstanceNames("SqlServerConfiguration");

#>

[PSCustomObject]$global:PVConfig = $null;

#region 'Constants'
Set-Variable -Name FINAL_NODE_EXPECTED_DIRECTORIES_KEYS -Option ReadOnly -Value @("VirtualSqlServerServiceAccessibleDirectories", "RawDirectories");
Set-Variable -Name FINAL_NODE_EXPECTED_SHARES_KEYS -Option ReadOnly -Value @("ShareName", "SourceDirectory", "ReadOnlyAccess", "ReadWriteAccess");
Set-Variable -Name FINAL_NODE_SQL_SERVER_INSTALLATION_KEYS -Option ReadOnly -Value @("SqlExePath", "StrictInstallOnly", "Setup", "ServiceAccounts", "SqlServerDefaultDirectories", "SecuritySetup");
Set-Variable -Name FINAL_NODE_SQL_SERVER_CONFIGURATION_KEYS -Option ReadOnly -Value @("LimitSqlServerTls1dot2Only", "GenerateSPN", "DisableSaLogin", "DeployContingencySpace", "EnabledUserRights", "TraceFlags");
Set-Variable -Name FINAL_NODE_ADMINDB_KEYS -Option ReadOnly -Value @("Deploy", "InstanceSettings", "DatabaseMail", "HistoryManagement", "DiskMonitoring", "Alerts", "IndexMaintenance", "ConsistencyChecks", "BackupJobs", "RestoreTestJobs");
Set-Variable -Name FINAL_NODE_EXTENDED_EVENTS_KEYS -Option ReadOnly -Value @("SessionName", "Enabled", "DefinitionFile", "StartWithSystem", "XelFileSizeMb", "XelFileCount", "XelFilePath");
Set-Variable -Name FINAL_NODE_SQL_SERVER_PATCH_KEYS -Option ReadOnly -Value @("TargetSP", "TargetCU");
Set-Variable -Name FINAL_NODE_AVAILABILITY_GROUP_KEYS -Option ReadOnly -Value @("AddPartners", "SyncCheckJobs", "AddFailoverProcessing", "CreateDisabledJobCategory", "Action", "Replicas", "Seeding", "Databases", "Listener", "Name", "PortNumber", "IPs", "ReadOnlyRounting", "GenerateClusterSPNs");

#TODO: ClusterWitness AND FileShareWitness can NOT _BOTH_ be 'terminal/final' keys... 
Set-Variable -Name FINAL_NODE_CLUSTER_CONFIGURATION_KEYS -Option ReadOnly -Value @("ClusterType", "PrimaryNode", "EvictionBehavior", "ClusterName", "ClusterNodes", "ClusterIPs", "ClusterDisks", "ClusterWitness", "FileShareWitness", "GenerateClusterSpns");

Set-Variable -Name BRANCH_NODE_EXTENDED_EVENTS_KEYS -Option ReadOnly -Value @("DisableTelemetry", "DefaultXelDirectory", "BlockedProcessThreshold");
Set-Variable -Name BRANCH_NODE_AVAILABILITY_GROUP_KEYS -Option ReadOnly -Value @("Enabled", "EvictionBehavior", "MirroringEndpoint", "SynchronizationChecks");

Set-Variable -Name ROOT_SQLINSTANCE_KEYS -Opt ReadOnly -Value @("ExpectedDirectories", "SqlServerInstallation", "SqlServerConfiguration", "SqlServerPatches", "AdminDb", "ExtendedEvents", "ResourceGovernor", "AvailabilityGroups", "CustomSqlScripts");
#endregion

filter Get-ProvisoConfigValueByKey {
	param (
		[Parameter(Mandatory)]
		[hashtable]$Config, # NOTE: $Config here can be $this (current config) OR it could be the list of DEFAULTS. 
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	$keys = $Key -split "\.";
	$output = $null;
	# vNext: I presume there's a more elegant way to do this... but, it works and ... I don't care THAT much.
	switch ($keys.Count) {
		1 {
			$output = $Config.($keys[0]);
		}
		2 {
			$output = $Config.($keys[0]).($keys[1]);
		}
		3 {
			$output = $Config.($keys[0]).($keys[1]).($keys[2]);
		}
		4 {
			$output = $Config.($keys[0]).($keys[1]).($keys[2]).($keys[3]);
		}
		5 {
			$output = $Config.($keys[0]).($keys[1]).($keys[2]).($keys[3]).($keys[4]);
		}
		default {
			throw "Invalid Key. Too many key segments defined.";
		}
	}
	
	return $output;
}

filter Get-KeyType {
	param (
		[string]
		$Key
	);
	
	switch (($Key -split '\.')[0]) {
		{ "Host" -eq $_ } {
			if (($Key -like 'Host.NetworkDefinitions*') -or ($Key -like "Host.ExpectedDisks*")) {
				return "Dynamic";
			}
			return "Static";
		}
		{ $_ -in "SqlServerManagementStudio", "ClusterConfiguration" } {
			return "Static";
		}
		{ $_ -in "ExpectedShares", "DataCollectorSets" } {
			return "Dynamic";
		}
		{ $_ -in "ExpectedDirectories", "SqlServerInstallation", "SqlServerConfiguration", "SqlServerPatches", "AdminDb" } {
			return "SqlInstance";
		}
		{ $_ -in "ExtendedEvents", "AvailabilityGroups", "ResourceGovernor", "CustomSqlScripts"	} {
			return "Complex"; # SqlInstance + Dynamic
		}
		default {
			throw "Proviso Framework Error. Unable to determine Key-Type of Key [$Key].";
		}
	}
}

filter Get-FacetTypeByKey {
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	$Key = Ensure-ProvisoConfigKeyIsNotImplicit -Key $Key;
	if (-not (Is-ValidProvisoKey -Key $Key)) {
		throw "Invalid Configuration Key: [$Key].";
	}
	
	$parts = $Key -split '\.';
	$output = $null;
	
	switch ($parts[0]) {
		"Host" {
			$output = "Simple";
			
			if ($parts[1] -in @("ExpectedDisks", "NetworkDefinitions")) {
				$output = "Object";
				
				if ("AssumableIfNames" -eq $parts[3]) {
					$output = "ObjectArray";
				}
			}
			elseif ("LocalAdministrators" -eq $parts[1]) {
				$output = "SimpleArray";
			}
		}
		"SqlServerManagementStudio" {
			$output = "Simple";
		}
		"ClusterConfiguration" {
			$output = "Simple";
			
			if ($parts[1] -in @("ClusterNodes", "ClusterIPs", "ClusterDisks")) {
				$output = "SimpleArray"
			}
		}
		{ $_ -in @("ExpectedShares", "DataCollectorSets") } {  # NOTE: Host.ExpectedDisks and Host.NetworkDefinitions have already been handled in the "Host" case... 
			$output = "Object";
			
			if ($parts[2] -in @("ReadOnlyAccess", "ReadWriteAccess")) {
				$output = "ObjectArray";
			}
		}
		{ $_ -in @("ExpectedDirectories", "SqlServerInstallation", "SqlServerConfiguration", "AdminDb", "SqlServerPatches", "ExtendedEvents") } {
			$output = "SqlObject";
			
			if ($parts[2] -in @("VirtualSqlServerServiceAccessibleDirectories", "RawDirectories", "TraceFlags")) {
				$output = "SqlObjectArray";
			}
			
			if ("MembersOfSysAdmin" -eq $parts[3]) {
				$output = "SqlObjectArray";
			}
		}
		{ $_ -in @("ExtendedEvents", "ResourceGovernor", "AvailabilityGroups", "CustomSqlScripts") } {
			$output = "Compound";
		}
		default {
			throw "Proviso Framework Error. Unidentified FacetType/Key: [$Key].";
		}	
	}
	
	return $output;		
}

filter Ensure-ProvisoConfigKeyIsNotImplicit {
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	$parts = $Key -split '\.';
	
	if ($parts[0] -in $ROOT_SQLINSTANCE_KEYS) {
		if ((Is-NonValidChildKey -ParentKey $parts[0] -TestKey $parts[1]) -or ($null -eq $parts[1])) {
			$explicitKey = $Key -replace $parts[0], "$($parts[0]).MSSQLSERVER";
			return $explicitKey;
		}
		
		switch ($parts[0]) {
			"ExtendedEvents" {
				switch ($parts.Count) {
					1 {
						throw "Invalid Configuration Key. ExtendedEvents keys must contain more than just the root element.";
					}
					2 {
						if ($parts[1] -in $BRANCH_NODE_EXTENDED_EVENTS_KEYS) {
							return "ExtendedEvents.MSSQLSERVER.($parts[1])";
						}
						else {
							if ($parts[1] -in $FINAL_NODE_EXTENDED_EVENTS_KEYS) {
								throw "Invalid Configuration Key. ExtendedEvents keys must specify a SQL Server instance as target.";
							}
							else {
								return $Key; # the key is a SQL Instance - i.e., "ExtendedEvents.X3" or "ExtendedEvents.Sales2014", etc
							}
						}
					}
					3 {
						if ($parts[2] -in $BRANCH_NODE_EXTENDED_EVENTS_KEYS) {
							return $Key; # legit - part[0] is ExtendedEvents, part[1] is an instance name, and part[2] is the terminator... e.g., "ExtendedEvents.MSSQLSERVER.DisableTelemetry"
						}
						else {
							if ($parts[2] -in $FINAL_NODE_EXTENDED_EVENTS_KEYS) {
								throw "Invalid Configuration Key. ExtendedEvents keys require a SQL Server Instance Name AND Extended Events Session name.";
							}
							else {
								return $Key; # legit - assuming that $part[2] is the name of an XE Session - e.g., "ExtendedEvents.MSSQLSERVER.BlockedProcesses";
							}
						}
					}
					4 {
						if ($parts[3] -notin $FINAL_NODE_EXTENDED_EVENTS_KEYS) {
							throw "Invalid Configuration Key. The final part of [$Key] is not a recognized ExtendedEvents Session Value.";
						}
						
						return $Key; # presumed legit ... but, more importantly: NOT implicit.
					}
				}
			}
		}
	}
	
	return $Key;
}

filter Ensure-ProvisoConfigKeyIsFormattedForObjects {
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	$parts = $Key -split '\.';
	if ("Host" -eq $parts[0]) {
		if ($parts[1] -in @("NetworkDefinitions", "ExpectedDisks")) {
			if ("{~ANY~}" -notin $parts) {
				return ($Key -replace $parts[1], "$($parts[1]).{~ANY~}");
			}
		}
	}
	
	if ($parts[0] -in @("ExpectedShares", "DataCollectorSets")) {
		if ("{~ANY~}" -notin $parts) {
			return ($Key -replace $parts[0], "$($parts[0]).{~ANY~}");
		}
	}
	
	if ($parts[0] -eq "ExtendedEvents") {
		if ($parts[2] -in $BRANCH_NODE_EXTENDED_EVENTS_KEYS) {
			return $Key;
		}
		elseif ("{~ANY~}" -notin $parts) {
			return ($Key -replace $parts[1], "$($parts[1]).{~ANY~}");
		}
		
		throw "Not Implemented: (Ensure-ProvisoConfigKeyIsFormattedForObjects for ExtendedEvents-objects).";
	}
	
	if ($parts[0] -in @("ResourceGovernor", "AvailabilityGroups", "CustomSqlScripts")) {
		if ("{~ANY~}" -notin $parts) {
			return ($Key -replace $parts[2], "{~ANY~}");
		}
		
		throw "Not Implemented (Ensure-ProvisoConfigKeyIsFormattedForObjects for COMPLEX objects).";
	}
	
	return $Key;
}

filter Is-NonValidChildKey {
	param (
		[string]$ParentKey,
		[string]$TestKey
	);
	
	[string[]]$stringsThatAreChildKeysNotSqlServerInstanceNames = @();
	
	switch ($ParentKey) {
		# Dynamic Keys: 
		"NetworkDefinitions" {
			$stringsThatAreChildKeysNotSqlServerInstanceNames += @("ProvisioningPriority", "InterfaceAlias", "AssumableIfNames", "IpAddress", "Gateway", "PrimaryDns", "SecondaryDns");
		}
		"ExpectedDisks" { 
			$stringsThatAreChildKeysNotSqlServerInstanceNames += @("ProvisioningPriority", "VolumeName", "VolumeLabel", "PhysicalDiskIdentifiers");
		}
		"ExpectedShares" {
			$stringsThatAreChildKeysNotSqlServerInstanceNames += $FINAL_NODE_EXPECTED_SHARES_KEYS;
		}
		"DataCollectorSets" {
			$stringsThatAreChildKeysNotSqlServerInstanceNames += @("Enabled", "EnableStartWithOS", "DaysWorthOfLogsToKeep");
		}
		# Sql Instance Keys:
		"ExpectedDirectories" {
			$stringsThatAreChildKeysNotSqlServerInstanceNames += $FINAL_NODE_EXPECTED_DIRECTORIES_KEYS;
		}
		"SqlServerInstallation" {
			$stringsThatAreChildKeysNotSqlServerInstanceNames += @("SqlExePath", "StrictInstallOnly", "Setup", "ServiceAccounts", "SqlServerDefaultDirectories", "SecuritySetup");
		}
		"SqlServerConfiguration"{
			$stringsThatAreChildKeysNotSqlServerInstanceNames += @("LimitSqlServerTls1dot2Only", "GenerateSPN", "DisableSaLogin", "DeployContingencySpace", "EnabledUserRights", "TraceFlags");
		}	
		"SqlServerPatches" {
			$stringsThatAreChildKeysNotSqlServerInstanceNames += @("TargetSP", "TargetCU");
		}
		"AdminDb" {
			# add common 'typos' or keys used as child keys that can't/shouldn't be SQL Server instance names: 
			$stringsThatAreChildKeysNotSqlServerInstanceNames += "Enabled";
			$stringsThatAreChildKeysNotSqlServerInstanceNames += $FINAL_NODE_ADMINDB_KEYS;
		}
		# Complex Keys: 
		"ExtendedEvents" {
			$stringsThatAreChildKeysNotSqlServerInstanceNames += $BRANCH_NODE_EXTENDED_EVENTS_KEYS;
			$stringsThatAreChildKeysNotSqlServerInstanceNames += $FINAL_NODE_EXTENDED_EVENTS_KEYS;
		}
		"ExtendedEvents.{~SQLINSTANCE~}" {
			$stringsThatAreChildKeysNotSqlServerInstanceNames += $FINAL_NODE_EXTENDED_EVENTS_KEYS;
		}
		"AvailabilityGroups"{
			#throw 'Proviso Framework Error. Determination of non-valid child keys for Availability Group Configuration has not been completed yet.';
			$stringsThatAreChildKeysNotSqlServerInstanceNames += $BRANCH_NODE_AVAILABILITY_GROUP_KEYS;
			$stringsThatAreChildKeysNotSqlServerInstanceNames += $FINAL_NODE_AVAILABILITY_GROUP_KEYS;
		}
		"ResourceGovernor" {
			throw 'Proviso Framework Error. Determination of non-valid child keys for Resource Governor Configuration has not been completed yet.';
		}
		"CustomSqlScripts" {
			throw 'Proviso Framework Error. Determination of non-valid child keys for Custom Sql Server Script Batches has not been completed yet.';
		}
	}
	
	return $stringsThatAreChildKeysNotSqlServerInstanceNames -contains $TestKey;
}

filter Is-InstanceGlobalComplexKey {
	# for Compound/Complex objects is this a 'global' key like, say, ExtendedEvents.MSSQLSERVER.DisableTelemetry
	# 	 or is it an objectKey - like, say: ExtendedEvents.MSSQLSERVER.BlockedProcesses.Enabled
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	$parts = $Key -split '\.';
	switch ($parts[0]) {
		"ExtendedEvents"		 {
			if ($parts[2] -in $BRANCH_NODE_EXTENDED_EVENTS_KEYS) {
				return $true;
			}
		}
		default {
			throw "Not Implemented: Is-InstanceGlobalComplexKey for type: [$($parts[0])].";
		}
	}
	
	return $false;
}

filter Get-TokenizableDefaultValueFromDefaultConfigSettings {
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	$value = Get-ProvisoConfigValueByKey -Config $script:be8c742fDefaultConfigData -Key $Key;
	
	if ($null -eq $value) {
		$keyType = Get-KeyType -Key $Key;
		
		$parts = $Key -split '\.';
		switch ($keyType) {
			"SqlInstance" {
				if (Is-NonValidChildKey -ParentKey $parts[0] -TestKey $parts[1]) {
					return $null; # i.e., the key is invalid
				}
				$sqlInstanceDefaultedKey = $Key -replace $parts[1], "{~SQLINSTANCE~}";
				$value = Get-ProvisoConfigValueByKey -Config $script:be8c742fDefaultConfigData -Key $sqlInstanceDefaultedKey;
				
			}
			"Dynamic" {
				$targetPart = 1;
				if ($Key -like 'Host*') {
					$targetPart = 2;
				}
				
				if (Is-NonValidChildKey -ParentKey $parts[$targetPart - 1] -TestKey $parts[$targetPart]) {
					return $null; # i.e., the key is invalid
				}
				
				$anyDefaultedKey = $Key -replace $parts[$targetPart], "{~ANY~}";
				$value = Get-ProvisoConfigValueByKey -Config $script:be8c742fDefaultConfigData -Key $anyDefaultedKey;
			}
			"Complex" {
				switch ($parts[0]) {
					
					"ExtendedEvents" {
						if ($parts[$parts.Count - 1] -in $BRANCH_NODE_EXTENDED_EVENTS_KEYS) {
							if ($parts.Count -eq 2) { 
								return $null; # this is an IMPLICIT key - which is illegal at this point, so return NULL/empty (just as would be the case with Is-NonValidChildKey - and, arguably, should PROBABLY handle this logic there?)
							}
							elseif ($parts.Count -eq 3) {
								$complexKey = $Key -replace $parts[1], "{~SQLINSTANCE~}";
							}
							else {
								throw "Invalid Configuration Key. Detected 'DisableTelemetery' at the wrong final position within Key: [$Key].";
							}
						}
						# now look for Object/child 'Final-Keys': 
						elseif ($parts[$parts.Count - 1] -in $FINAL_NODE_EXTENDED_EVENTS_KEYS) {
							if ($parts.Count -eq 3) { # assume that the key is implicit (might not be ... but if it's not meh... )
								$complexKey = $Key -replace $parts[0], "$($parts[0]).{~SQLINSTANCE~}";
							}
							elseif ($parts.Count -eq 4) {
								$complexKey = $Key -replace $parts[1], "{~SQLINSTANCE~}";
								$complexKey = $complexKey -replace $parts[2], "{~ANY~}";
							}
							else {
								throw "Invalid Configuration Key. Detected '$($parts[$parts.Count - 1])' at the wrong final position within Key: [$Key].";
							}
						}
						else {
							# at this point, presumably, all we have left would be something like "ExtendedEvents.MSSQLSERVER.BlockedProcesses" or "ExtendedEvents.BlockedProcesses"
							# 		i.e., some sort of 'key-group' lookup that's either implicit or explicit - but which ISN'T trying to pull 'child' keys. 
							if ($parts.Count -eq 2) {
								$complexKey = "ExtendedEvents.{~SQLINSTANCE~}.{~ANY~}";
							}
							elseif ($parts.Count -eq 3) {
								$complexKey = "ExtendedEvents.{~SQLINSTANCE~}.{~ANY~}";
							}
							else {
								throw "Invalid Configuration Key. Unknown final-position key '$($parts[$parts.Count - 1])' in Key: [$Key].";
							}
						}
					}
					"ResourceGovernor" {
						throw "Not Implemented.";
					}
					"AvailabilityGroups" {
						throw "Not Implemented.";
					}
					"CustomSqlScripts" {
						throw "Not Implemented.";
					}
					default {
						throw "Proviso Framework Error. Unknown Compound-Key type detected for Key: [$Key].";
					}
				}
				
				$value = Get-ProvisoConfigValueByKey -Config $script:be8c742fDefaultConfigData -Key $complexKey;
			}
		}
	}
	
	return $value;
}

filter Is-ValidProvisoKey {
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	if ($null -eq $script:be8c742fDefaultConfigData) {
		throw "Proviso Framwork Error. Proviso Config Defaults are not yet loaded.";
	}
	
	try {
		$value = Get-TokenizableDefaultValueFromDefaultConfigSettings -Key $Key;
	}
	catch {
		return $false; # anything that threw an exception would be ... because of an INVALID key... 
	}
	
	return ($null -ne $value);
}

filter Get-ProvisoConfigDefaultValue {
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	if ($null -eq $script:be8c742fDefaultConfigData) {
		throw "Proviso Framwork Error. Proviso Config Defaults are not yet loaded.";
	}
	
	if (-not (Is-ValidProvisoKey -Key $Key)) {
		throw "Invalid Configuration Key: [$Key].";
	}
	
	$value = Get-TokenizableDefaultValueFromDefaultConfigSettings -Key $Key;
	if ($value -is [hashtable]) {
		$reloadValues = $false;
		if ($Key -like "*PhysicalDiskIdentifiers") {
			$reloadValues = $true;
		}
		
		# This is a BIT of a weird hack to get around cases where request of an entire 'block' of data results in ... nuffin' but defaults.
		if ($reloadValues) {
			$newValue = @{};
			foreach ($valueKey in $value.Keys) {
				$reloadFullKey = "$Key.$valueKey";
				$reloadValue = Get-KeyValue -Key $reloadFullKey;
				
				$newValue.Add($valueKey, $reloadValue)
			}
			return $newValue;
		}
	}
	
	# check for {PARENT}, {PROHIBITED}, {EMPTY}, etc. 
	if ("{~DEFAULT_PROHIBITED~}" -eq $value) {
		throw "Default Values for Key: [$Key] are NOT permitted. Please provide an explicit value via configuration file or through explictly defined inputs.";
	}
	
	if ("{~DEFAULT_IGNORED~}" -eq $value) {
		return $null;
	}
	
	if ("{~EMPTY~}" -eq $value) { # NOTE: this if-check sucks. It's PowerShell 'helping me'. I should have to check for ($value -is [string[]]) -and ($value.count -eq 1) -and ("{~EMPTY~}" -eq $value[0])
		return $null;
	}
		
	if ("{~PARENT~}" -eq $value) {
		$pattern = $null;
		switch ($Key) {
			{ $_ -like "Host*" } {
				$pattern = 'Host.(NetworkDefinitions|ExpectedDisks).(?<parent>[^\.]+).(VolumeLabel|InterfaceAlias)';
			}
			{ $_ -like "ExpectedShares*" } {
				$pattern = 'ExpectedShares.(?<parent>[^\.]+).ShareName';
			}
			{ $_ -like "ExtendedEvents*" } {
				$pattern = 'ExtendedEvents.(?<sqlinstance>[^\.]+).(?<parent>[^\.]+).SessionName';
			}
			{ $_ -like "ResourceGovernor*" } {
				throw "Resource Governor {~PARENT~} key defaults are not supported - YET.";
			}
			default {
				throw "Provoso Framework Error. Unmatched {~PARENT~} key type for Key [$Key].";
			}
		}
		
		$match = [regex]::Matches($Key, $pattern, 'IgnoreCase');
		if ($match) {
			$value = $match[0].Groups['parent'].Value;
		}
		else {
			throw "Proviso Framework Error. Unable to determine {~PARENT~} for key [$Key].";
		}
	}
	
	if ("{~DYNAMIC~}" -eq $value) {
		
		$parts = $Key -split '\.';
		
		switch ($Key) {
			{ $_ -like '*SqlTempDbFileCount' } {
				$coreCount = Get-WindowsCoreCount;
				if ($coreCount -le 4) {
					return $coreCount;
				}
				return 4;
			}
			{ $_ -like "*SqlServerInstallation*SqlServerDefaultDirectories*" } {
				$match = [regex]::Matches($Key, 'SqlServerInstallation\.(?<instanceName>[^\.]+).', 'IgnoreCase');

				if ($match) {
					$instanceName = $match[0].Groups['instanceName'];
					$directoryName = $parts[$parts.length - 1];
					
					return Get-SqlServerDefaultDirectoryLocation -InstanceName $instanceName -SqlDirectory $directoryName;
				}
				else {
					throw "Proviso Framework Error. Non-Default SQL Server Instance for SQL Server Default Directories threw an exception.";
				}
			}
			{ $_ -like "SqlServerInstallation*Setup*Instal*Directory"} {
				$instanceName = $parts[1];
				$directoryName = $parts[3];
				
				return Get-SqlServerDefaultInstallationPath -InstanceName $instanceName -DirectoryName $directoryName;
			}
			{ $_ -like "*ServiceAccounts*"} {
				$match = [regex]::Matches($Key, 'SqlServerInstallation\.(?<instanceName>[^\.]+).', 'IgnoreCase');
				if ($match) {
					$instanceName = $match[0].Groups['instanceName'];
					$serviceName = $parts[$parts.length - 1];
					
					return Get-SqlServerDefaultServiceAccount -InstanceName $instanceName -AccountType $serviceName;
				}
				else {
					throw "Proviso Framework Error. Non-Default SQL Server Instance for SQL Server Default Directories threw an exception.";
				}
			}
			{ $_ -like "Admindb*TimeZoneForUtcOffset" } {
				throw "Proviso Framework Error. TimeZone-Offsets have not YET been made dynmaic.";
			}
			{ $_ -like "DataCollectorSets*XmlDefinition" }  {
				$match = [regex]::Matches($Key, 'SDataCollectorSets.(?<instanceName>[^\.]+).(?<setName>[^\.]+).XmlDefinition');
				if ($match) {
					$collectorSetName = $match[0].Groups['setName'].Value;
					
					return "$collectorSetName.xml";
				}
				else {
					throw "Proviso Framework Error. Unable to determine default value of XmlDefinition for Data Collector Set for Key: [$Key]."
				}
			}
			{ $_ -like "ExtendedEvents*DefinitionFile" } {
				# MKC: This DYNAMIC functionality might end up being really Stupid(TM). 
				#  		Convention is that <XeSession>.DefinitionFile defaults to "(<XeSession>.SessionName).sql". 
				# 		ONLY: 
				# 		1. Complexity: <XeSession>.SessionName can be EMPTY and, by definition, defaults to <XeSession> - i.e., we're at potentially 2x redirects for defaults at this point.
				#		2. We're currently in the 'GetDefaultValue' func - meaning it's POSSIBLE that a config hasn't even been loaded yet. 				
				try {
					$sessionNameKey = $Key -replace "DefinitionFile", "SessionName";
					$sessionName = $this[$sessionNameKey]; # Do NOT recurse using $this.GetValue() - i.e., attempt to use $this as a collection instead. 
					return "$($sessionName).sql";
				}
				catch {
					# if we fail, return the parent/node name instead. MIGHT be a bad idea (see comments above).
					return "$($parts[2]).sql";
				}
			}
			default {
				throw "Proviso Framework Error. Invalid {~DYNAMIC~} default provided for key: [$Key].";
			}
		}
	}
	
	return $value;
}

# TODO: use private variable here instead of misdirection (i.e. Set-Variable xxx -Visibility Private)
$script:be8c742fFlattenedConfigKeys = $null;
filter Recurse-Keys {
	param (
		[Parameter(Mandatory)]
		[hashtable]$Source,
		[string]$ParentKey = ""
	);
	
	foreach ($kvp in $Source.GetEnumerator()) {
		$key = $kvp.Key;
		$value = $kvp.Value;
		
		$chainedKey = $key;
		if (-not ([string]::IsNullOrEmpty($ParentKey))) {
			$chainedKey = "$ParentKey.$key";
		}
		
		if ($value -is [hashtable]) {
			$script:be8c742fFlattenedConfigKeys.Add($chainedKey, $value);
			Recurse-Keys -Source $value -ParentKey $chainedKey;
		}
		else {
			$script:be8c742fFlattenedConfigKeys.Add($chainedKey, $value);
		}
	}
}

filter Get-KeyValue {
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	# vNEXT: I _COULD_ route keys through Ensure-ProvisoConfigKeyIsNotImplicit (and potentially even Ensure-ProvisoConfigKeyIsFormattedForObjects)
	# 	to address scenarios of if/when code calls for something like $PVConfig.GetValue("Admindb.Deployed") - to 'switch that' to "AdminDb.MSSQLSERVER.Deployed". 
	# ONLY... while I COULD do that, the reality is that all Surfaces/Aspects/Facets SHOULD be wired to call for these keys CORRECTLY (i.e., non-implicitly).
	
	if (-not (Is-ValidProvisoKey -Key $Key)) {
		throw "Fatal Error. Invalid Configuration key requested: [$Key].";
	}
	
	$output = $this[$Key];
	
	if (-not ($this.AllowDefaults) -or ($null -ne $output)) {
		return $output;
	}

	return Get-ProvisoConfigDefaultValue -Key $Key;
}

filter Set-KeyValue {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Key,
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Value
	);
	
	if ($this.ContainsKey($Key)) {
		$this[$Key] = $Value;
	}
	else {
		$this.Add($Key, $Value);
	}
}

filter Get-ConfigSqlInstanceNames {
	param (
		[parameter(Mandatory)]
		[string]$Key
	);
	
	$parts = $Key -split '\.';
	$target = $parts[0];
	
	$instances = @();
	if ($target -in $ROOT_SQLINSTANCE_KEYS) {
		foreach ($sqlKey in $this.Keys) {
			if ($sqlKey -like "$($target)*") {
				$instance = ($sqlKey -split '\.')[1];
				
				# MKC: ... sigh. once again: super confused by how this code EVEN WORKS. 
				#  		i.e., the -notin BELOW is a hack. (BUT, how come i don't have to set up -notin entries for, say, Deploy, DatabaseMail, and a bazillion other entries inside of Admindb.x?)
				if ($instance -notin @("OverrideSource")) {
					
					if ($instances -notcontains $instance) {
						$instances += $instance
					}
				}
				
			}
		}
	}
	
	return $instances;
}

filter Get-ClusterWitnessTypeFromConfig {
	# Simple 'helper' for DRY purposes... 
	# May, EVENTUALLY, need to add a param here for the SQL Server INSTANCE... 
	
	$share = $PVConfig.GetValue("ClusterConfiguration.Witness.FileShareWitness");
	$disk = $PVConfig.GetValue("ClusterConfiguration.Witness.DiskWitness");
	$cloud = $PVConfig.GetValue("ClusterConfiguration.Witness.AzureCloudWitness");
	$quorum = $PVConfig.GetValue("ClusterConfiguration.Witness.Quorum");
	
	$witnessType = "NONE";
	if ($share) {
		$witnessType = "FILESHARE";
	}
	if ($disk) {
		if ("NONE" -ne $witnessType) {
			throw "Invalid Configuration. Clusters may only have ONE configured/defined Witness type. Comment-out or remove all but ONE witness definition.";
		}
		$witnessType = "DISK";
	}
	if ($cloud) {
		if ("NONE" -ne $witnessType) {
			throw "Invalid Configuration. Clusters may only have ONE configured/defined Witness type. Comment-out or remove all but ONE witness definition.";
		}
		$witnessType = "CLOUD";
	}
	if ($quorum) {
		if ("NONE" -ne $witnessType) {
			throw "Invalid Configuration. Clusters may only have ONE configured/defined Witness type. Comment-out or remove all but ONE witness definition.";
		}
		$witnessType = "QUORUM";
	}
	
	return $witnessType;
}

filter Get-ClusterWitnessDetailFromConfig {
	param (
		[string]$ClusterType = $null
	);
	
	if ([string]::IsNullOrEmpty($ClusterType)) {
		$ClusterType = Get-ClusterWitnessTypeFromConfig;
	}

	switch ($ClusterType) {
		"NONE" {
			return "";
		}
		"FILESHARE" {
			return $PVConfig.GetValue("ClusterConfiguration.Witness.FileShareWitness");
		}
		"DISK" {
			return $PVConfig.GetValue("ClusterConfiguration.Witness.DiskWitness");
		}
		"CLOUD" {
			return $PVConfig.GetValue("ClusterConfiguration.Witness.AzureCloudWitness");
		}
		"QUORUM" {
			return $true;
		}
		default {
			throw "Proviso Framework Error. Invalid ClusterType defined: [$ClusterType].";
		}
	}
}

filter Get-FileShareWitnessPathFromConfig {
	[string]$expectedPath = $PVConfig.GetValue("ClusterConfiguration.Witness.FileShareWitness");
	if ([string]::IsNullOrEmpty($expectedPath)) {
		throw "Invalid Operation. Can not set file share witness path to EMPTY value.";
	}
	
	# This is fine: "\\somserver\witnesses" - whereas this will FAIL EVERY TIME: "\\somserver\witnesses\"
	if ($expectedPath.EndsWith('\')) {
		$expectedPath = $expectedPath.Substring(0, ($expectedPath.Length - 1));
	}
	
	return $expectedPath;
}

filter Get-ConfigObjects {
	param (
		[parameter(Mandatory)]
		[string]$Key
	);
	
	$parts = $Key -split '\.';
	$target = 1;
	$leadingKey = "$($parts[0])*";
	
	if ($parts[0] -in @("Host", "ExtendedEvents", "ResourceGovernor", "AvailabilityGroups", "CustomSqlScripts")) {
		$target = 2;
		$leadingKey = "$($parts[0]).$($parts[1])*";
	}
	
	$objects = @();
	foreach ($objectKey in $this.Keys) {
		if ($objectKey -like $leadingKey) {
			$objectName = ($objectKey -split '\.')[$target];
			
			if ($objects -notcontains $objectName) {
				$objects += $objectName;
			}
		}
	}
	
	if ("ExtendedEvents" -eq $parts[0]) {
		$objects = @($objects | Where-Object { $_ -notlike "*isableTelemetry" });
	}
	
	return $objects;
}

filter Set-ConfigTarget {
	param (
		[Parameter(Mandatory)]
		[hashtable]$ConfigData,
		[switch]$Strict = $false,
		[switch]$AllowDefaults = $true
	);
	
	if ($null -eq $script:be8c742fDefaultConfigData) {
		$script:be8c742fDefaultConfigData = $script:ProvisoConfigDefaults;
	}
	
	if ($Strict) {
		if ($null -eq $ConfigData.Host.TargetServer) {
			throw "Fatal Error. Switch -Strict set to $true, but the [Host.TargetServer] was not found within input defined via -ConfigData parameter.";
		}
		
		$currentHostName = [System.Net.Dns]::GetHostName();
		if ($currentHostName -ne $ConfigData.Host.TargetServer) {
			throw "Fatal Error. Switch -Strict is set to $true, but Current Host Name of [$currentHostName] does not match [$($ConfigData.Host.TargetServer)].";
		}
	}
	
	# validate config inputs/data: 
	$script:be8c742fFlattenedConfigKeys = @{};
	Recurse-Keys -Source $ConfigData;
	
	$hashtableForPVConfigContents = @{};
	
	foreach ($key in $script:be8c742fFlattenedConfigKeys.Keys | Sort-Object { $_ }) {
		
		$value = Get-ProvisoConfigValueByKey -Config $ConfigData -Key $key;
		
		if ("{~DEFAULT_INGORED~}" -eq $value) {
			continue;
		}
		
		#region OLD Comments on how confusing this next bit of code is... (i.e., IGNORE-ish)
		# MKC: the ELSE clause below needs to be removed/reworked. 
		# 	I THINK it's some bit of 'extra protection/validation' added in 'after the fact' that tries to do a couple of things: 
		# 		1. watch for invalid 'terminator' keys... 
		# 			Only, it does NOT do that correctly - it's checking parts[1] all the time/etc... 
		# 			i.e., it's NOT strong enough for LEGIT evaluations... so, all it does is CAUSE PROBLEMS with things that should, otherwise, be FINE. 
		# 		2. shift IMPLICIT keys that are NOT yet valid (ExtendedEvents.DisableTelemetry) to explicit keys (ExtendedEvents.MSSQLSERVER.DisableTelemetry)
		# 			which is great... 
		# 			but... i think the fix there should be: 
		# 				a. get rid of all of the termination/final-node checking. 
		# 				b. do the replace that's defined AFTER the switch (i.e., make things explicit)
		# 				c. ... run an ADDITIONAL check to see if the key is NOW valid. 
		#   and... yeah... looks like that totally worked. 
		#endregion
		
		# MKC: 
		# 	This code/logic is confusing. 
		#   Effectively: 
		# 		loop through ALL keys in the .psd1 file (or source). 
		# 		if the file is a LEGIT key ... then just add it in (unless it's a hashtable... (then just ignore it, its CHILDREN will get added as needed.)
		# 		if it's NOT valid... then, it SHOULD just be an IMPLICIT key that needs to be made into an EXPLICIT key (e.g., parts[0] + .MSSQLSERVER)
		# 			arguably, there could, also be a scenario where the key - after being made explicit, MIGHT? need place-holders for {~ANY~}... 
		# 			but I don't THINK so???? 
		
		if (Is-ValidProvisoKey -Key $key) {
			
			if ($value -isnot [hashtable]) {
				$hashtableForPVConfigContents.Add($key, $value);
			}
		}
		else {
			$parts = $key -split '\.';
			$explicitKey = $key -replace "$($parts[0])", "$($parts[0]).MSSQLSERVER";
			
			if (-not (Is-ValidProvisoKey -Key $explicitKey)) {
				throw "Fatal Error. Invalid Configuration Key Encountered while Executing Import from config file. Key: [$key].";
			}
			
			$hashtableForPVConfigContents.Add($explicitKey, $value);
		}
	}
	
	# add members/etc. 
	[PSCustomObject]$configObject = $hashtableForPVConfigContents;
	
	$configObject | Add-Member -MemberType NoteProperty -Name Strict -Value $Strict -Force;
	$configObject | Add-Member -MemberType NoteProperty -Name AllowDefaults -Value $AllowDefaults -Force;
	
	$configObject | Add-Member -MemberType ScriptMethod -Name GetValue -Value ((Get-Item "Function:\Get-KeyValue").ScriptBlock) -Force;
	$configObject | Add-Member -MemberType ScriptMethod -Name SetValue -Value ((Get-Item "Function:\Set-KeyValue").ScriptBlock) -Force;
	$configObject | Add-Member -MemberType ScriptMethod -Name GetDefault -Value ((Get-Item "Function:\Get-ProvisoConfigDefaultValue").ScriptBlock) -Force;
	$configObject | Add-Member -MemberType ScriptMethod -Name GetSqlInstanceNames -Value ((Get-Item "Function:\Get-ConfigSqlInstanceNames").ScriptBlock) -Force;
	$configObject | Add-Member -MemberType ScriptMethod -Name GetObjects -Value ((Get-Item "Function:\Get-ConfigObjects").ScriptBlock) -Force;
	
	# assign as global/intrinsic: 
	$global:PVConfig = $configObject;
}