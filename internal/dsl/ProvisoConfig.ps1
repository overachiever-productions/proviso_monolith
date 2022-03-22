Set-StrictMode -Version 1.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Assign -ProvisoRoot "\\storage\Lab\proviso\";
	Target "\\storage\lab\proviso\definitions\PRO\PRO-197.psd1" -Strict:$false;

#>


[PSCustomObject]$global:PVConfig = $null;

# 'Constants':
Set-Variable -Name Node_3_ExpectedDirectories_Keys -Option ReadOnly -Value @("VirtualSqlServerServiceAccessibleDirectories", "RawDirectories");
Set-Variable -Name Node_3_ExpectedShares_Keys -Option ReadOnly -Value @("ShareName", "SourceDirectory", "ReadOnlyAccess", "ReadWriteAccess");
Set-Variable -Name Node_3_SqlServerInstallation_Keys -Option ReadOnly -Value @("SqlExePath", "StrictInstallOnly", "Setup", "ServiceAccounts", "SqlServerDefaultDirectories", "SecuritySetup");
Set-Variable -Name Node_3_AdminDb_Keys -Option ReadOnly -Value @("Deploy", "InstanceSettings", "DatabaseMail", "HistoryManagement", "DiskMonitoring", "Alerts", "IndexMaintenance", "ConsistencyChecks", "BackupJobs", "RestoreTestJobs");
Set-Variable -Name FINAL_NODE_EXTENDED_EVENTS_KEYS -Option ReadOnly -Value @("Enabled", "SessionName", "StartWithSystem", "EnabledAtCreation");

Set-Variable -Name ROOT_SQLINSTANCE_KEYS -Opt ReadOnly -Value @("ExpectedDirectories", "SqlServerInstallation", "SqlServerConfiguration", "SqlServerPatches", "AdminDb", "ExtendedEvents", "ResourceGovernor", "AvailabilityGroups", "CustomSqlScripts");

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
			$explicitKey = $Key -replace $parts[0], "$($parts[0]).{~SQLINSTANCE~}";
			return $explicitKey;
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
	
	if ($parts[0] -in @("ExtendedEvents", "ResourceGovernor", "AvailabilityGroups", "CustomSqlScripts")) {
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
			$stringsThatAreChildKeysNotSqlServerInstanceNames += $Node_3_ExpectedShares_Keys;
		}
		"DataCollectorSets" {
			$stringsThatAreChildKeysNotSqlServerInstanceNames += @("Enabled", "EnableStartWithOS", "DaysWorthOfLogsToKeep");
		}
		# Sql Instance Keys:
		"ExpectedDirectories" {
			$stringsThatAreChildKeysNotSqlServerInstanceNames += $Node_3_ExpectedDirectories_Keys;
		}
		"SqlServerInstallation" {
			$stringsThatAreChildKeysNotSqlServerInstanceNames += @("SqlExePath", "StrictInstallOnly", "Setup", "ServiceAccounts", "SqlServerDefaultDirectories", "SecuritySetup");
		}
		"SqlServerConfiguration"{
			$stringsThatAreChildKeysNotSqlServerInstanceNames += @("LimitSqlServerTls1dot2Only", "GenerateSPN", "DisablSaLogin", "DeployContingencySpace", "EnabledUserRights", "TraceFlags");
		}	
		"SqlServerPatches" {
			#$stringsThatAreChildKeysNotSqlServerInstanceNames += @("
			throw 'Proviso Framework Error. Determination of non-valid child keys for SQL Server Patches has not been completed yet.';
		}
		"AdminDb" {
			# add common 'typos' or keys used as child keys that can't/shouldn't be SQL Server instance names: 
			$stringsThatAreChildKeysNotSqlServerInstanceNames += "Enabled";
			$stringsThatAreChildKeysNotSqlServerInstanceNames += $Node_3_AdminDb_Keys;
		}
		# Complex Keys: 
		"ExtendedEvents" {
			$stringsThatAreChildKeysNotSqlServerInstanceNames += @("DisableTelemetry", "Enabled", "SessionName", "StartWithSystem", "EnabledAtCreation");
		}
		"ExtendedEvents.{~SQLINSTANCE~}" {
			$stringsThatAreChildKeysNotSqlServerInstanceNames += $FINAL_NODE_EXTENDED_EVENTS_KEYS;
		}
		"AvailabilityGroups"{
			throw 'Proviso Framework Error. Determination of non-valid child keys for Availability Group Configuration has not been completed yet.';
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
						# look for instance-level 'globals' - i.e., 'simple' SqlObject keys/details... (vs SqlObject + Object values (compound)).
						if ("DisableTelemetry" -eq $parts[$parts.Count - 1]) {
							if ($parts.Count -eq 2) { # implicit... so, make it explicit:
								$complexKey = "ExtendedEvents.{~SQLINSTANCE~}.DisableTelemetry";
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
			default {
				throw "Proviso Framework Error. Invalid {~DYNAMIC~} default provided for key: [$Key].";
			}
		}
	}
	
	return $value;
}

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
				
				if ($instances -notcontains $instance) {
					$instances += $instance
				}
			}
		}
	}
	
	return $instances;
}

filter Get-ConfigObjects {
	param (
		[parameter(Mandatory)]
		[string]$Key
	);
	
	$parts = $Key -split '\.';
	$target = 1;
	$leadingKey = "$($parts[0])*";
	if ("Host" -eq $parts[0]) {
		$target = 2;
		$leadingKey = "Host.$($parts[1])*";
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
		
		if (Is-ValidProvisoKey -Key $key) {
			if ($value -isnot [hashtable]) {
				$hashtableForPVConfigContents.Add($key, $value);
			}
		}
		else {
			$parts = $key -split '\.';
			
			switch ($key) {
				{ $_ -like "SqlServerInstallation*"	} {
					if ($parts[1] -notin $Node_3_SqlServerInstallation_Keys) {
						throw "Fatal Error. Invalid SqlServerInstallation Configuration Key: [$key].";
					}
				}
				{ $_ -like "AdminDb*" } {
					if ($parts[1] -notin $Node_3_AdminDb_Keys) {
						throw "Fatal Error. Invalid AdminDb Configuration Key: [$key].";
					}
				}
				{ $_ -like "ExpectedDirectories*" } {
					if ($parts[1] -notin $Node_3_ExpectedDirectories_Keys) {
						throw "Fatal Error. Invalid ExpectedDirectories Configuration Key: [$key].";
					}
				}
				{ $_ -like "ExpectedShares*" } {
					if ($parts[1] -notin $Node_3_ExpectedShares_Keys) {
						throw "Fatal Error. Invalid ExpectedShares Configuration Key: [$key].";
					}
				}
				{ $_ -like "ExtendedEvents*" } {
					if ($parts[1] -notin $FINAL_NODE_EXTENDED_EVENTS_KEYS) {
						throw "Fatal Error. Invalid Extended Events Configuration Key: [$key].";
					}
				}
				default {
					throw "Fatal Error. Invalid Configuration Key: [$key].";
				}
			}
	
			$explicitKey = $key -replace "$($parts[0])", "$($parts[0]).MSSQLSERVER";
			$hashtableForPVConfigContents.Add($explicitKey, $value);
		}
	}
	
	# add members/etc. 
	[PSCustomObject]$configObject = $hashtableForPVConfigContents;
	
	$configObject | Add-Member -MemberType NoteProperty -Name Strict -Value $Strict -Force;
	$configObject | Add-Member -MemberType NoteProperty -Name AllowDefaults -Value $AllowDefaults -Force;
	
	[ScriptBlock]$getValue = (Get-Item "Function:\Get-KeyValue").ScriptBlock;
	[ScriptBlock]$setValue = (Get-Item "Function:\Set-KeyValue").ScriptBlock;
	#[ScriptBlock]$groupNames = (Get-Item "Function:\Get-ProvisoConfigGroupNames").ScriptBlock;
	[ScriptBlock]$sqlNames = (Get-Item "Function:\Get-ConfigSqlInstanceNames").ScriptBlock;
	[ScriptBlock]$objectNames = (Get-Item "Function:\Get-ConfigObjects").ScriptBlock;
	
	$configObject | Add-Member -MemberType ScriptMethod -Name GetValue -Value $getValue -Force;
	$configObject | Add-Member -MemberType ScriptMethod -Name SetValue -Value $setValue -Force;
	#$configObject | Add-Member -MemberType ScriptMethod -Name GetGroupNames -Value $groupNames -Force;
	$configObject | Add-Member -MemberType ScriptMethod -Name GetSqlInstanceNames -Value $sqlNames -Force;
	$configObject | Add-Member -MemberType ScriptMethod -Name GetObjects -Value $objectNames -Force;
	
	# assign as global/intrinsic: 
	$global:PVConfig = $configObject;
}