Set-StrictMode -Version 1.0;

[PSCustomObject]$global:PVConfig = $null;

# 'Constants':
Set-Variable -Name Node_3_ExpectedDirectories_Keys -Option ReadOnly -Value @("VirtualSqlServerServiceAccessibleDirectories", "RawDirectories");
Set-Variable -Name Node_3_ExpectedShares_Keys -Option ReadOnly -Value @("ShareName", "SourceDirectory", "ReadOnlyAccess", "ReadWriteAccess");
Set-Variable -Name Node_3_SqlServerInstallation_Keys -Option ReadOnly -Value @("SqlExePath", "StrictInstallOnly", "Setup", "ServiceAccounts", "SqlServerDefaultDirectories", "SecuritySetup");
Set-Variable -Name Node_3_AdminDb_Keys -Option ReadOnly -Value @("Deploy", "InstanceSettings", "DatabaseMail", "HistoryManagement", "DiskMonitoring", "Alerts", "IndexMaintenance", "ConsistencyChecks", "BackupJobs", "RestoreTestJobs");
Set-Variable -Name Node_3_ExtendedEvents_Keys -Option ReadOnly -Value @("Enabled", "SessionName", "StartWithSystem", "EnabledAtCreation");

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
			$stringsThatAreChildKeysNotSqlServerInstanceNames += $Node_3_ExtendedEvents_Keys;
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
				if (Is-NonValidChildKey -ParentKey $parts[0] -TestKey $parts[1]) {
					return $null; # i.e., the key is invalid
				}
		
				if (Is-NonValidChildKey -ParentKey ("$($parts[0]).{~SQLINSTANCE~}") -TestKey $parts[1]) {
					return $null; # i.e., the key is invalid
				}
				
				$complexKey = $Key -replace $parts[1], "{~SQLINSTANCE~}";
				
				if (($Key -like "ExtendedEvents*DisableTelemetry")) {
					# TODO: this is a one-off (for now)... just need to figure out how to do this for 'Surface-Globals' - i.e., a 'global' config key/value for a specific surface's SQL Instance... etc. 
					$complexKey = "ExtendedEvents.{~SQLINSTANCE~}.DisableTelemetry";
				}
				elseif ($parts.Count -gt 2) {
					$complexKey = $Key -replace $parts[2], "{~ANY~}";
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
	
	# check for {PARENT}, {PROHIBITED}, {EMPTY}
	if ("{~DEFAULT_PROHIBITED~}" -eq $value) {
		throw "Default Values for Key: [$Key] are NOT permitted. Please provide an explicit value via configuration file or through explictly defined inputs.";
	}
	
	if ("{~EMPTY~}" -eq $value) { # NOTE: this if-check sucks. It's PowerShell 'helping me'. I should have to check for ($value -is [string[]]) -and ($value.count -eq 1) -and ("{~EMPTY~}" -eq $value[0])
		return ""; # I should have to return @() for keys expecting arrays (vs scalar empty strings). but... PowerShell 'helps' there too. 
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
				#$pattern = 'ExtendedEvents.(?<sqlinstance>[^\.]+).(?<sessionName>[^\.]+).SessionName';
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
	
	if (-not (Is-ValidProvisoKey -Key $Key)) {
		throw "Fatal Error. Invalid Configuration key requested: [$Key].";
	}
	
	# Uhh. Either flattening keys (via RecurseKeys) into the $pvStateHashtable and/or converting that to PSCustomObject 'converted'
	# 		the keys to the point where they're simple, string, keys at this point - which is perfect. (It's what I wanted). 
	# 		That said, the DEFAULTS object is ... still the old/multi-hashtable/multi-keys kind of object so need the 'helper' method to traverse it.
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
	
	# See notes in Get-KeyValue about accessing keys in $this vs $provisoDefaults hashtable... 
	if ($this.ContainsKey($Key)) {
		$this[$Key] = $Value;
	}
	else {
		$this.Add($Key, $Value);
	}
}

filter Get-ProvisoConfigGroupNames {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$GroupKey,
		[string]$OrderByKey
	);
	
	Write-Host "doling stuff"
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
	
	# actually. no. fixed by simply NOT adding legit values that are hash-tables. 
	# So... need to extract this foreach into a func of its own. that'll take in a hashtable of values and ... run through each. 
	# 		and, for each, it'll see if key is valid or ... not. and if not, try to cast from implict to explict - otherwise, throw. 
	# 		but, where it IS valid. IF the $value -is [hashtable] ... I then need to recurse ... over that hashtable - i.e. for each key... is it legit? 
	# 			and so on... 
	foreach ($key in $script:be8c742fFlattenedConfigKeys.Keys | Sort-Object { $_ }) {
		
		$value = Get-ProvisoConfigValueByKey -Config $ConfigData -Key $key;
		if (Is-ValidProvisoKey -Key $key) {
			if ($value -isnot [hashtable]) {
				# a hashtable at, say. "SqlServerInstallation" might contain an entire 'list' of 'bad'(implict) keys... and adding them causes a 'leak' of implicit keys. 
				# 	whereas, interestingly enough, as we iterate EACH key... whether the hashtable was 'bad' or 'good', it gets added 'anyhow'
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
					if ($parts[1] -notin $Node_3_ExtendedEvents_Keys) {
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
	
	#$hashtableForPVConfigContents.Keys | Sort-Object { $_ } | Format-List;
	
	# add members/etc. 
	[PSCustomObject]$configObject = $hashtableForPVConfigContents;
	
	$configObject | Add-Member -MemberType NoteProperty -Name Strict -Value $Strict -Force;
	$configObject | Add-Member -MemberType NoteProperty -Name AllowDefaults -Value $AllowDefaults -Force;
	
	[ScriptBlock]$getValue = (Get-Item "Function:\Get-KeyValue").ScriptBlock;
	[ScriptBlock]$setValue = (Get-Item "Function:\Set-KeyValue").ScriptBlock;
	[ScriptBlock]$groupNames = (Get-Item "Function:\Get-ProvisoConfigGroupNames").ScriptBlock;
	
	$configObject | Add-Member -MemberType ScriptMethod -Name GetValue -Value $getValue -Force;
	$configObject | Add-Member -MemberType ScriptMethod -Name SetValue -Value $setValue -Force;
	$configObject | Add-Member -MemberType ScriptMethod -Name GetGroupNames -Value $groupNames -Force;
	
	# assign as global/intrinsic: 
	$global:PVConfig = $configObject;
}
#
#. .\ProvisoConfig-Defaults.ps1;
#$script:be8c742fDefaultConfigData = $script:ProvisoConfigDefaults;
#
#$ConfigFile = "\\storage\lab\proviso\definitions\PRO\PRO-197.psd1";
#$data = Import-PowerShellDataFile $ConfigFile;
#
#Set-ConfigTarget -ConfigData $data -Strict:$false -AllowDefaults;

#$PVConfig.GetValue("AdminDb.Deploy");  # should throw... (does)

# TODO: there's a potential problem with this one:
#$PVConfig.GetValue("AdminDb.MSSQLSERVER.Deploy"); # should return #true via explicit config... and does. 
#$PVConfig.GetValue("AdminDb.MSSQLSERVER.DatabaseMail.OperatorEmail");
#$PVConfig.GetValue("SqlServerInstallation.MSSQLSERVER.Setup.InstallDirectory");
#$PVConfig.GetValue("ExpectedDirectories.MSSQLSERVER.RawDirectories");

# Defaults:
#Write-Host "Defaults:"
#$PVConfig.GetValue("SqlServerInstallation.MSSQLSERVER.SETUP.SqlTempdbFileSize");
#
## settting a default value - explicitly
#$PVConfig.SetValue("SqlServerInstallation.MSSQLSERVER.SETUP.SqlTempdbFileSize", 2048); # should overwrite default and set.. 
#$PVConfig.GetValue("SqlServerInstallation.MSSQLSERVER.SETUP.SqlTempdbFileSize"); # should, now, report 2048 vs 1024


# overwritting a non-default: 
#$PVConfig.GetValue("AdminDb.MSSQLSERVER.DatabaseMail.SmtpPassword");
#$PVConfig.SetValue("AdminDb.MSSQLSERVER.DatabaseMail.SmtpPassword", "secret and stuff");
#$PVConfig.GetValue("AdminDb.MSSQLSERVER.DatabaseMail.SmtpPassword");

#$PVConfig.GetGroupNames("Admindb.")
