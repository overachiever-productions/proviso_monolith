Set-StrictMode -Version 1.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	
	Map -ProvisoRoot "\\storage\Lab\proviso\";
	Target -ConfigFile "\\storage\lab\proviso\definitions\PRO\PRO-197.psd1" -Strict:$false;

	Get-ConfigurationEntry -Key "SqlServerInstallation.MSSQLSERVER.Setup.SqlTempDbFileCount";

	#Get-ConfigurationEntry -Key "ExtendedEvents.Sessions.BlockedProcesses.XelFileSizeMb";
	#Get-ConfigurationEntry -Key "ExtendedEvents.DisableTelemetry";
	
	#Validate-ConfigurationEntry -Key "ExtendedEvents.Sessions.BlockedProcesses.DefinitionFile";
	#Get-ConfigurationEntry -Key "ExtendedEvents.Sessions.BlockedProcesses.DefinitionFile";
	
	$PVConfig.GetValue("ExtendedEvents.Sessions.BlockedProcesses.DefinitionFile");

#>

$script:be8c742fFlattenedConfigKeys = $null;
$script:be8c742fLatestConfigData = $null;
$script:hashtableForPVConfigContents = $null;

filter Get-ProvisoConfigDataType {
	param (
		[Object]$Value = $null
	);
	
	if ($null -eq $Value) {
		return [Proviso.Enums.ConfigEntryDataType]::Null;
	}
	
	if ($Value -is [array]) {
		return [Proviso.Enums.ConfigEntryDataType]::Array;
	}
	else {
		switch ($Value.GetType().Name) {
			"Hashtable" {
				return [Proviso.Enums.ConfigEntryDataType]::HashTable;
			}
			default {
				return [Proviso.Enums.ConfigEntryDataType]::Scalar;
			}
		}
	}
}

filter Get-AllowableChildKeyNames {
	# Internal ONLY. Keys must be FULLY/PERFECTLY formatted and tokenized. 
	param (
		[string]$Key = ""
	);
	
	$config = $script:ProvisoConfigDefaults;
	
	$output = @();
	if ([string]::IsNullOrEmpty($Key)) {
		foreach ($keyName in $config.Keys) {
			$output += $keyName;
		}
		
		return $output;
	}
	
	$targetSection = Extract-ValueFromConfigByKey -Config $config -Key $Key;
	foreach ($subKey in $targetSection.Keys) {
		$output += $subKey;
	}
	
	return $output;
}

filter Extract-ValueFromConfigByKey {
	param (
		[Parameter(Mandatory)]
		[hashtable]$Config, 	# NOTE: $Config here can be $this (current config) OR it could be the list of DEFAULTS.
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	$keys = $Key -split "\.";
	$output = $null;
	# this isn't SUPER elegant ... but it works (and perf is not an issue).
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
		6 {
			$output = $Config.($keys[0]).($keys[1]).($keys[2]).($keys[3]).($keys[4]).($keys[5]);
		}
		7 {
			$output = $Config.($keys[0]).($keys[1]).($keys[2]).($keys[3]).($keys[4]).($keys[5]).($keys[6]);
		}
		8 {
			$output = $Config.($keys[0]).($keys[1]).($keys[2]).($keys[3]).($keys[4]).($keys[5]).($keys[6]).($keys[7]);
		}
		default {
			throw "Invalid Key. Too many key segments defined.";
		}
	}
	
	return $output;
}

filter Ascertain-ExplicitOrImplicitSqlInstance {
	param (
		[Parameter(Mandatory)]
		[Proviso.Processing.ConfigEntry]$ConfigEntry,
		[Parameter(Mandatory)]
		[string[]]$AcceptableNodes,
		[Parameter(Mandatory)]
		[ValidateRange(0, 6)]
		[int]$Start
	);
	
	$key = $ConfigEntry.OriginalKey;
	$parts = $ConfigEntry.KeyParts;
	if ($parts.Count -lt 2) {
		$ConfigEntry.NormalizedKey = $ConfigEntry.OriginalKey;
		$ConfigEntry.SqlInstanceKeyType = [Proviso.Enums.SqlInstanceKeyType]::NotApplicable;
		return $ConfigEntry;
	}
	
	$currentTestSlot = $Start;
	$testTargetSlot = $parts[$currentTestSlot];
	if ($testTargetSlot -in $AcceptableNodes) {
		$ConfigEntry.SqlInstanceKeyType = [Proviso.Enums.SqlInstanceKeyType]::Implicit;
		$ConfigEntry.SqlInstanceName = "MSSQLSERVER";
		
		# HMMM. Might need to pass in a '-ReplacementDelegate' parameter to format this stuff?
		$ConfigEntry.NormalizedKey = $key -replace "$($parts[0]).", "$($parts[0]).MSSQLSERVER.";
		$ConfigEntry.TokenizedKey = $key -replace "$($parts[0]).", "$($parts[0]).{~SQLINSTANCE~}."; # tempting to try and 'reuse' logic from normalizedKey... but TINY chance 'mssqlserver' shows up 2x in the key?
		
		$ConfigEntry.IsValid = $true;
	}
	else {
		$currentTestSlot++;
		$testTargetSlot = $parts[$currentTestSlot];
		if ($testTargetSlot -in $AcceptableNodes) {
			$ConfigEntry.SqlInstanceKeyType = [Proviso.Enums.SqlInstanceKeyType]::Explicit;

			$sqlInstanceName = $parts[($currentTestSlot) - 1];
			$ConfigEntry.SqlInstanceName = $sqlInstanceName;
			
			$ConfigEntry.NormalizedKey = $key;
					
			# TODO: Limit to replacing only the FIRST instance of $sqlInstanceName. Sadly, -replace does NOT support this. So I'll need to use regex. Docs for -replace: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comparison_operators?view=powershell-7.2
			$ConfigEntry.TokenizedKey = $key -replace $sqlInstanceName, "{~SQLINSTANCE~}";
			
			$ConfigEntry.IsValid = $true;
		}
		else {
			if ($parts.Count -eq 2) {
				# At this point we know: a) root is legit + SqlInstance-able b) part[1] is NOT a sub-key IF this was an IMPLICIT key... 
				# 		so, only option is: this is a request for an entire SQL Server instance node:
				$ConfigEntry.IsValid = $true;
				$ConfigEntry.SqlInstanceName = $parts[1];
				$ConfigEntry.TokenizedKey = $key -replace $parts[1], "{~SQLINSTANCE~}";
				$ConfigEntry.SqlInstanceKeyType = [Proviso.Enums.SqlInstanceKeyType]::Explicit;
			}
			else {
				$ConfigEntry.IsValid = $false;
				$ConfigEntry.InvalidReason = "Unable to determine explicit or implicit SQL Server Instance name for key [$($ConfigEntry.OriginalKey)] - Normalization Failure.";
				$ConfigEntry.SqlInstanceKeyType = [Proviso.Enums.SqlInstanceKeyType]::Invalid;
			}
		}
	}
	
	return $ConfigEntry;
}

filter Process-ImplicitOrExplicitSqlServerInstanceDetails {
	param (
		[Parameter(Mandatory)]
		[Proviso.Processing.ConfigEntry]$ConfigEntry
	);
	
	if (-not ($ConfigEntry.IsValid)) {
		return $ConfigEntry;
	}
	
	$parts = $ConfigEntry.KeyParts;
	switch ($parts[0]) {
		{ $_ -in @("Host", "ExpectedShares", "DataCollectorSets", "SqlServerManagementStudio") }	 {
			$ConfigEntry.SqlInstanceKeyType = [Proviso.Enums.SqlInstanceKeyType]::NotApplicable;
			$ConfigEntry.NormalizedKey = $ConfigEntry.OriginalKey;
			$ConfigEntry.TokenizedKey = $ConfigEntry.OriginalKey;
			return $ConfigEntry; # nothing to do here - these aren't SQLInstance-aware/capable.
		}
		#"AnyKindOfCustomOrVariableConfigSectionWithDifferentRules" {
		#	# Place-holder for implementation of any CUSTOM logic (either different args to Ascertain-Explicit/Implicit OR full-blown, 100% different logic)
		#	# 	for the implmentation of any SPECIALIZED config nodes. 
		#   #  NOTE: make sure to set .NormalizedKey... and .TokenizedKey as applicable.
		#}
		#region stupid logic for ExtendedEvents (not used - I don't think)
#		"ExtendedEvents" {
#			# These are a bit of a challenge - due to the notion of 'top level' values. 
#			$acceptableGlobalKeys = Get-AllowableChildKeyNames -Key "ExtendedEvents.{~SQLINSTANCE~}";
#				switch ($parts.Count) {
#					1 {
#						return $ConfigEntry; # nothing to normalize... 
#					}
#					2 {
#						if ($parts[1] -in $acceptableGlobalKeys) {
#							$ConfigEntry.SqlInstanceKeyType = [Proviso.Enums.SqlInstanceKeyType]::Implicit;
#							$ConfigEntry.SqlInstanceName = "MSSQLSERVER";
#							$ConfigEntry.NormalizedKey = "ExtendedEvents.MSSQLSERVER.$($parts[1])";
#							$ConfigEntry.TokenizedKey = "ExtendedEvents.{~SQLINSTANCE~}.$($parts[1])";
#						}
#						else {
#							$ConfigEntry.SqlInstanceKeyType = [Proviso.Enums.SqlInstanceKeyType]::Explicit;
#							$ConfigEntry.SqlInstanceName = $parts[1];
#							$ConfigEntry.NormalizedKey = "ExtendedEvents.$($parts[1])";
#							$ConfigEntry.TokenizedKey = "ExtendedEvents.{~SQLINSTANCE~}";
#						}
#					}
#					3 {
#						if ($parts[2] -in $acceptableGlobalKeys) {
#							$ConfigEntry.SqlInstanceKeyType = [Proviso.Enums.SqlInstanceKeyType]::Explicit;
#							$ConfigEntry.SqlInstanceName = $parts[1];
#							$ConfigEntry.NormalizedKey = "ExtendedEvents.$($parts[1]).$($parts[2])";
#							$ConfigEntry.TokenizedKey = "ExtendedEvents.{~SQLINSTANCE~}.$($parts[2])";
#						}
#						else {
#							# Could be explicit - e.g., "ExtendedEvents.BlockedProcesses.SessionName"
#						}
#					}
#					4 {
#						
#					}
#					default {
#						throw "Invalid Length";
#					}
#				}
#				
#				return $ConfigEntry;
		#		}		
		#endregion
		default { 	# this addresses most/all(?) SqlInstance-aware config-blocks:
			$legitThirdSlotKeyNames = Get-AllowableChildKeyNames -Key "$currentRootNode.{~SQLINSTANCE~}";
			return Ascertain-ExplicitOrImplicitSqlInstance -ConfigEntry $ConfigEntry -AcceptableNodes $legitThirdSlotKeyNames -Start 1;
		}
	}
}

filter Process-ObjectInstanceTokenization {
	param (
		[Parameter(Mandatory)]
		[Proviso.Processing.ConfigEntry]$ConfigEntry
	);
	
	if (-not ($ConfigEntry.IsValid)) {
		return $ConfigEntry;
	}
	
	$currentRootNode = $ConfigEntry.ConfigRoot;
	
	if ($ConfigEntry.SqlInstanceKeyType -notin @("Implicit", "Explicit", "NotApplicable")) {
		throw "Invalid Operation. Key [$($ConfigEntry.OriginalKey)] can NOT be evaluated for tokenization until it has been normalized.";
	}
	
	$normalizedParts = $ConfigEntry.NormalizedKey -split '\.';
	
	switch ($currentRootNode) {
		"Host" {
			if ($normalizedParts.Count -ge 3) {
				if ($normalizedParts[1] -in @("NetworkDefinitions", "ExpectedDisks")) {
					
					$childKeysForHostObjects = Get-AllowableChildKeyNames -Key "Host.$($normalizedParts[1]).{~ANY~}";
					
					if ($normalizedParts[2] -in $childKeysForHostObjects) {
						$ConfigEntry.IsValid = $false;
						
						$objectType = "disk";
						if ($normalizedParts[1] -eq "NetworkDefinitions") {
							$objectType = "adapter";
						}
						
						$ConfigEntry.InvalidReason = "Expected a [$objectType] name - but value [$($normalizedParts[2])] is an attribute instead.";
					}
					else {
						$ConfigEntry.ObjectInstanceName = $normalizedParts[2];
		
						$ConfigEntry.TokenizedKey = $ConfigEntry.TokenizedKey -replace $normalizedParts[2], "{~ANY~}";
					}
				}
			}
		}
		"ExpectedShares" {
			if ($normalizedParts.Count -ge 2) {
				$childKeys = Get-AllowableChildKeyNames -Key "ExpectedShares.{~ANY~}";
				
				if ($normalizedParts.Count -gt 2) {
					if ($normalizedParts[2] -in $childKeys) {
						$ConfigEntry.IsValid = $true;
						$ConfigEntry.ObjectInstanceName = $normalizedParts[1];
						$ConfigEntry.TokenizedKey = $ConfigEntry.OriginalKey -replace $normalizedParts[1], "{~ANY~}";
					}
					else {
						$ConfigEntry.IsValid = $false;
						$ConfigEntry.InvalidReason = "Key [$($normalizedParts[2])] is not a valid attribute for Shares.";
					}
				}
				else {
					if ($normalizedParts[1] -in $childKeys) {
						$ConfigEntry.IsValid = $false;
						$ConfigEntry.InvalidReason = "Expected the name of a Share but value [$($normalizedParts[1])] is a share attribute instead.";
					}
					else {
						$ConfigEntry.IsValid = $true;
						$ConfigEntry.ObjectInstanceName = $normalizedParts[1];
						$ConfigEntry.TokenizedKey = $ConfigEntry.OriginalKey -replace $normalizedParts[1], "{~ANY~}";
					}
				}
			}
		}
		"ExtendedEvents" {
			if ($normalizedParts.Count -ge 4) {
				$allowableChildKeys = Get-AllowableChildKeyNames -Key "ExtendedEvents.{~SQLINSTANCE~}.Sessions.{~ANY~}";
				
				if ($normalizedParts[3] -in $allowableChildKeys) {
					$ConfigEntry.IsValid = $false;
					$ConfigEntry.InvalidReason = "Expected an Extended Events Session-Name but, instead, recieved [$($normalizedParts[3])] - which is a Session attribute.";
				}
				else {
					$parentKeys = Get-AllowableChildKeyNames -Key "ExtendedEvents.{~SQLINSTANCE~}";
					if ($normalizedParts[2] -notin $parentKeys) {
						$ConfigEntry.IsValid = $false;
						$ConfigEntry.InvalidReason = "Mal-formed Extended Events Configuration Key."; # create some tests to see if this  scenario is even a concern... 
					}
					else {
						$ConfigEntry.ObjectInstanceName = $normalizedParts[3];
						$ConfigEntry.TokenizedKey = $ConfigEntry.TokenizedKey -replace $normalizedParts[3], "{~ANY~}";
					}
				}
			}
		}
		"DataCollectorSets" {
			
			# REFACTOR: 
			# 	COPY / PASTE / TWEAK (minor text changes) from ExpectedShares  (just changes $childKeys root lookup, and "shares" to "Data Collector Sets" in INvalidReasons. That's it)
			if ($normalizedParts.Count -ge 2) {
				$childKeys = Get-AllowableChildKeyNames -Key "DataCollectorSets.{~ANY~}";
				
				if ($normalizedParts.Count -gt 2) {
					if ($normalizedParts[2] -in $childKeys) {
						$ConfigEntry.IsValid = $true;
						$ConfigEntry.ObjectInstanceName = $normalizedParts[1];
						$ConfigEntry.TokenizedKey = $ConfigEntry.OriginalKey -replace $normalizedParts[1], "{~ANY~}";
					}
					else {
						$ConfigEntry.IsValid = $false;
						$ConfigEntry.InvalidReason = "Key [$($normalizedParts[2])] is not a valid attribute for Data Collector Sets.";
					}
				}
				else {
					if ($normalizedParts[1] -in $childKeys) {
						$ConfigEntry.IsValid = $false;
						$ConfigEntry.InvalidReason = "Expected the name of a Share but value [$($normalizedParts[1])] is a Data Collector Set attribute instead.";
					}
					else {
						$ConfigEntry.IsValid = $true;
						$ConfigEntry.ObjectInstanceName = $normalizedParts[1];
						$ConfigEntry.TokenizedKey = $ConfigEntry.OriginalKey -replace $normalizedParts[1], "{~ANY~}";
					}
				}
			}
		}
		"AvailabilityGroups" {
			if ($normalizedParts.Count -ge 4) {
				$agChildElements = Get-AllowableChildKeyNames -Key "AvailabilityGroups.{~SQLINSTANCE~}.Groups.{~ANY~}";
				
				if ($normalizedParts[3] -in $agChildElements) {
					$ConfigEntry.IsValid = $false;
					$ConfigEntry.InvalidReason = "Expected the name of an Availability Group but value [$($normalizedParts[3])] is an attribute instead.";
				}
				else {
					if ($normalizedParts.Count -gt 4) {
						if ($normalizedParts[4] -in $agChildElements) {
							$ConfigEntry.IsValid = $true;
							$ConfigEntry.ObjectInstanceName = $normalizedParts[3];
							$ConfigEntry.TokenizedKey = $ConfigEntry.TokenizedKey -replace $normalizedParts[3], "{~ANY~}";
						}
						else {
							Write-Host "hmmm"
						}
					}
					else {
						$ConfigEntry.IsValid = $true;
						$ConfigEntry.ObjectInstanceName = $normalizedParts[3];
						$ConfigEntry.TokenizedKey = $ConfigEntry.TokenizedKey -replace $normalizedParts[3], "{~ANY~}";
					}
				}
			}
		}
		default {
			# no sub-groups/objects to process or account for... 
		}
	}
	
	return $ConfigEntry;
}

filter Process-KeyValidationViaDefaultValueExtraction {
	param (
		[Parameter(Mandatory)]
		[Proviso.Processing.ConfigEntry]$ConfigEntry
	);
	
	if (-not ($ConfigEntry.IsValid)) {
		return $ConfigEntry;
	}
	
	if ($null -eq $ConfigEntry.TokenizedKey) {
		$ConfigEntry.TokenizedKey = $ConfigEntry.OriginalKey;
	}
	
	$defaultValue = Extract-ValueFromConfigByKey -Config $script:ProvisoConfigDefaults -Key $ConfigEntry.TokenizedKey;
	if ($null -eq $defaultValue) {
		$ConfigEntry.IsValid = $false;
		$ConfigEntry.InvalidReason = "The key [$($ConfigEntry.OriginalKey)] is not recognized by Proviso.";
	}
	else {
		$ConfigEntry.IsValid = $true; # attempting to grab the explicit value can set this to false... 
		$ConfigEntry.DefaultDataType = Get-ProvisoConfigDataType -Value $defaultValue;
		$ConfigEntry.DefaultValue = $defaultValue;
	}
	
	return $ConfigEntry;
}

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

filter Normalize-UserSuppliedConfigData {
	param (
		[Parameter(Mandatory)]
		[hashtable]$ConfigData
	);
	
	if ($null -eq $script:be8c742fDefaultConfigData) {
		$script:be8c742fDefaultConfigData = $script:ProvisoConfigDefaults;
	}
	
	$script:be8c742fLatestConfigData = $ConfigData;
	
	$script:be8c742fFlattenedConfigKeys = @{};
	Recurse-Keys -Source $ConfigData;
	
	$script:hashtableForPVConfigContents = @{};
	foreach ($key in $script:be8c742fFlattenedConfigKeys.Keys | Sort-Object { $_ }) {
		$value = Extract-ValueFromConfigByKey -Config $ConfigData -Key $key;
		
		$normalizedOnlyEntry = Validate-ConfigurationEntry -Key $key;
		
		if(-not([string]::IsNullOrEmpty($normalizedOnlyEntry.NormalizedKey))){
			$key = $normalizedOnlyEntry.NormalizedKey;
		}
		
		$script:hashtableForPVConfigContents.Add($key, $value);
	}
	
}

filter Validate-ConfigurationEntry {
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	[Proviso.Processing.ConfigEntry]$entry = [Proviso.Processing.ConfigEntry]::ConfigEntryFromKey($Key);
	
	$currentRootNode = $entry.ConfigRoot;
	$rootNodes = Get-AllowableChildKeyNames -Key "";
	if ($currentRootNode -notin $rootNodes) {
		$entry.IsValid = $false;
		$entry.InvalidReason = "Root of key [$Key] is not a supported configuration key type.";
	}
	else {
		$entry.IsValid = $true; # it's true for NOW...  (any of the following could switch it to false if it's no longer legit)
		
		$entry = Process-ImplicitOrExplicitSqlServerInstanceDetails($entry);
		$entry = Process-ObjectInstanceTokenization($entry);
		
		$entry = Process-KeyValidationViaDefaultValueExtraction($entry);
	}
	
	return $entry;
}

filter Extract-ExplicitValue {
	param (
		[Parameter(Mandatory)]
		[Proviso.Processing.ConfigEntry]$ConfigEntry
	);
	
	if (-not ($ConfigEntry.IsValid)) {
		return $ConfigEntry;
	}
	
	if ($null -eq $ConfigEntry.NormalizedKey) {
		$ConfigEntry.NormalizedKey = $ConfigEntry.OriginalKey;
	}
	
	try {
		$explicitValue = $global:PVConfig[$ConfigEntry.NormalizedKey];
		
		$ConfigEntry.DataType = Get-ProvisoConfigDataType -Value $explicitValue;
		$ConfigEntry.Value = $explicitValue; # might be null or even "", etc.
	}
	catch {
		$ConfigEntry.IsValid = $false;
		$ConfigEntry.InvalidReason = "Exception: $_ ";
	}
	
	return $ConfigEntry;
}

filter Get-ConfigurationEntry {
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	if ($null -eq $global:PVConfig) {
		throw "Explicit Values can NOT be extracted until a valid -Target has been specified."
	}
	
	[Proviso.Processing.ConfigEntry]$entry = Validate-ConfigurationEntry -Key $Key;
	return Extract-ExplicitValue -ConfigEntry $entry;
}

filter Process-SpecializedProvisoDefault {
	param (
		[Parameter(Mandatory)]
		[string]$NormalizedKey,
		[Parameter(Mandatory)]
		[string]$DefaultToken
	);
	
	switch ($DefaultToken) {
		"{~DEFAULT_PROHIBITED~}" {
			throw "Default Values for Key: [$NormalizedKey] are NOT permitted. Please provide an explicit value via configuration file or through explictly defined inputs.";
		}
		"{~EMPTY~}" {
			return $null;
		}
		"{~PARENT~}" {
			$pattern = $null;
			switch ($NormalizedKey) {
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
			
			$match = [regex]::Matches($NormalizedKey, $pattern, 'IgnoreCase');
			if ($match) {
				$value = $match[0].Groups['parent'].Value;
			}
			else {
				throw "Proviso Framework Error. Unable to determine {~PARENT~} for key [$NormalizedKey].";
			}
		}
		"{~DYNAMIC~}" {
			$parts = $NormalizedKey -split '\.';
			
			switch ($NormalizedKey) {
				{ $_ -like '*SqlTempDbFileCount' } {
					$coreCount = Get-WindowsCoreCount;
					if ($coreCount -le 4) {
						return $coreCount;
					}
					return 4;
				}
				{ $_ -like "*SqlServerInstallation*SqlServerDefaultDirectories*" } {
					$match = [regex]::Matches($NormalizedKey, 'SqlServerInstallation\.(?<instanceName>[^\.]+).', 'IgnoreCase');
					
					if ($match) {
						$instanceName = $match[0].Groups['instanceName'];
						$directoryName = $parts[$parts.length - 1];
						
						return Get-SqlServerDefaultDirectoryLocation -InstanceName $instanceName -SqlDirectory $directoryName;
					}
					else {
						throw "Proviso Framework Error. Non-Default SQL Server Instance for SQL Server Default Directories threw an exception.";
					}
				}
				{ $_ -like "SqlServerInstallation*Setup*Instal*Directory" } {
					$instanceName = $parts[1];
					$directoryName = $parts[3];
					
					return Get-SqlServerDefaultInstallationPath -InstanceName $instanceName -DirectoryName $directoryName;
				}
				{ $_ -like "*ServiceAccounts*" } {
					$match = [regex]::Matches($NormalizedKey, 'SqlServerInstallation\.(?<instanceName>[^\.]+).', 'IgnoreCase');
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
					$match = [regex]::Matches($NormalizedKey, 'SDataCollectorSets.(?<instanceName>[^\.]+).(?<setName>[^\.]+).XmlDefinition');
					if ($match) {
						$collectorSetName = $match[0].Groups['setName'].Value;
						
						return "$collectorSetName.xml";
					}
					else {
						throw "Proviso Framework Error. Unable to determine default value of XmlDefinition for Data Collector Set for Key: [$NormalizedKey]."
					}
				}
				{ $_ -like "ExtendedEvents*DefinitionFile" } {
					# MKC: This DYNAMIC functionality might end up being really Stupid(TM). 
					#  		Convention is that <XeSession>.DefinitionFile defaults to "(<XeSession>.SessionName).sql". 
					# 		ONLY: 
					# 		1. Complexity: <XeSession>.SessionName can be EMPTY and, by definition, defaults to <XeSession> - i.e., we're at potentially 2x redirects for defaults at this point.
					#		2. We're currently in the 'GetDefaultValue' func - meaning it's POSSIBLE that a config hasn't even been loaded yet. 				
					try {
						$sessionNameKey = $NormalizedKey -replace "DefinitionFile", "SessionName";
						$sessionName = $this[$sessionNameKey]; # Do NOT recurse using $this.GetValue() - i.e., attempt to use $this as a collection instead. 
						return "$($sessionName).sql";
					}
					catch {
						# if we fail, return the parent/node name instead. MIGHT be a bad idea (see comments above).
						return "$($parts[2]).sql";
					}
				}
				default {
					throw "Proviso Framework Error. Invalid {~DYNAMIC~} default provided for key: [$NormalizedKey].";
				}
			}
		}
		default {
			throw;
		}
	}
	
	return $value;
}

filter Is-ValidProvisoKey {
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	try {
		$entry = Validate-ConfigurationEntry -Key $Key;
		
		return $entry.IsValid;
	}
	catch {
		return $false;
	}
}

filter Get-FacetTypeByKey {
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	$entry = Validate-ConfigurationEntry -Key $Key;
	if (-not ($entry.IsValid)) {
		throw "Key [$Key] is Invalid: $($entry.InvalidReason).";
	}
	
	$Key = $entry.NormalizedKey;

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
		{ $_ -in @("ExpectedShares", "DataCollectorSets") } {
			# NOTE: Host.ExpectedDisks and Host.NetworkDefinitions have already been handled in the "Host" case... 
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

filter Get-KeyValue {
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	[Proviso.Processing.ConfigEntry]$output = Get-ConfigurationEntry -Key $Key;
	if (-not ($output.IsValid)) {
		throw "Key [$Key] is Invalid: $($output.InvalidReason)";
	}
	
	if (-not ($global:PVConfig.AllowDefaults) -or ($null -ne $output.Value)) {
		return $output.Value;
	}
	else {
		if ($output.DefaultValue -like "{~*~}") {
			return Process-SpecializedProvisoDefault -NormalizedKey ($output.NormalizedKey) -DefaultToken ($output.DefaultValue) ;
		}
		else {
			return $output.DefaultValue;
		}
	}
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
	
	throw "Set-KeyValue is NOT Implemented Yet...";
	
	# TODO: validate/verify the key being passed in - as in... make sure it's normalized and tokenizable and the whole 9 yards
	
	
#	if ($this.ContainsKey($Key)) {
#		$this[$Key] = $Value;
#	}
#	else {
#		$this.Add($Key, $Value);
#	}
}

filter Get-SqlInstanceNames {
	param (
		[parameter(Mandatory)]
		[string]$Key
	);
	
	$tokenized = Validate-ConfigurationEntry -Key $Key;
	if (-not ($tokenized.IsValid)) {
		throw "Invalid Key. Key [$Key] is Invalid: $($tokenized.InvalidReason)";
	}
	
	$tokenizedKey = $tokenized.TokenizedKey;
	# SQL Server Instance name is ALWAYS parts[1] (i.e., second key). If that ever changes, will need to create a switch in here to evaluate/etc. 
	$leadingEdge = ($tokenizedKey -split '\.')[0];
	
	$instanceNames = @();
	foreach ($sqlKey in $this.Keys) {
		if ($sqlKey -like "$leadingEdge*") {
			
			$instanceName = (($sqlKey -replace "$($leadingEdge).", "") -split '\.')[0];
			
			if ($instanceName -ne $leadingEdge) {
				if ($instanceNames -notcontains $instanceName) {
					
					$instanceNames += $instanceName;
				}
			}
		}
	}
	
	return $instanceNames;
}

filter Get-ObjectInstanceNames {
	param (
		[parameter(Mandatory)]
		[string]$Key
	);
	
	$tokenized = Validate-ConfigurationEntry -Key $Key;
	if (-not ($tokenized.IsValid)) {
		throw "Invalid Key. Key [$Key] is Invalid: $($tokenized.InvalidReason)";
	}
	
	$tokenizedKey = $tokenized.TokenizedKey;
#	if ($tokenizedKey -notlike "*{~ANY~}*") {
#		throw "Invalid Operation. Key [$Key] does NOT target object instances.";
#	}
	
	$leadingEdge = ($tokenizedKey -split '{~ANY~}')[0];
	$objects = @();
	foreach ($objectKey in $this.Keys) {
		if ($objectKey -like "$leadingEdge*") {
			
			$objectInstanceName = (($objectKey -replace $leadingEdge, "") -split '\.')[0]
			
			if ($objects -notcontains $objectInstanceName) {
				$objects += $objectInstanceName;
			}
		}
	}
	
	return $objects;
}

#region Recovered Older Code
#filter Get-ClusterWitnessTypeFromConfig {
#	# Simple 'helper' for DRY purposes... 
#	# May, EVENTUALLY, need to add a param here for the SQL Server INSTANCE... 
#	
#	$share = $PVConfig.GetValue("ClusterConfiguration.Witness.FileShareWitness");
#	$disk = $PVConfig.GetValue("ClusterConfiguration.Witness.DiskWitness");
#	$cloud = $PVConfig.GetValue("ClusterConfiguration.Witness.AzureCloudWitness");
#	$quorum = $PVConfig.GetValue("ClusterConfiguration.Witness.Quorum");
#	
#	$witnessType = "NONE";
#	if ($share) {
#		$witnessType = "FILESHARE";
#	}
#	if ($disk) {
#		if ("NONE" -ne $witnessType) {
#			throw "Invalid Configuration. Clusters may only have ONE configured/defined Witness type. Comment-out or remove all but ONE witness definition.";
#		}
#		$witnessType = "DISK";
#	}
#	if ($cloud) {
#		if ("NONE" -ne $witnessType) {
#			throw "Invalid Configuration. Clusters may only have ONE configured/defined Witness type. Comment-out or remove all but ONE witness definition.";
#		}
#		$witnessType = "CLOUD";
#	}
#	if ($quorum) {
#		if ("NONE" -ne $witnessType) {
#			throw "Invalid Configuration. Clusters may only have ONE configured/defined Witness type. Comment-out or remove all but ONE witness definition.";
#		}
#		$witnessType = "QUORUM";
#	}
#	
#	return $witnessType;
#}
#
#filter Get-ClusterWitnessDetailFromConfig {
#	param (
#		[string]$ClusterType = $null
#	);
#	
#	if ([string]::IsNullOrEmpty($ClusterType)) {
#		$ClusterType = Get-ClusterWitnessTypeFromConfig;
#	}
#	
#	switch ($ClusterType) {
#		"NONE" {
#			return "";
#		}
#		"FILESHARE" {
#			return $PVConfig.GetValue("ClusterConfiguration.Witness.FileShareWitness");
#		}
#		"DISK" {
#			return $PVConfig.GetValue("ClusterConfiguration.Witness.DiskWitness");
#		}
#		"CLOUD" {
#			return $PVConfig.GetValue("ClusterConfiguration.Witness.AzureCloudWitness");
#		}
#		"QUORUM" {
#			return $true;
#		}
#		default {
#			throw "Proviso Framework Error. Invalid ClusterType defined: [$ClusterType].";
#		}
#	}
#}
#
#filter Get-FileShareWitnessPathFromConfig {
#	[string]$expectedPath = $PVConfig.GetValue("ClusterConfiguration.Witness.FileShareWitness");
#	if ([string]::IsNullOrEmpty($expectedPath)) {
#		throw "Invalid Operation. Can not set file share witness path to EMPTY value.";
#	}
#	
#	# This is fine: "\\somserver\witnesses" - whereas this will FAIL EVERY TIME: "\\somserver\witnesses\"
#	if ($expectedPath.EndsWith('\')) {
#		$expectedPath = $expectedPath.Substring(0, ($expectedPath.Length - 1));
#	}
#	
#	return $expectedPath;
#}
#endregion

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
	
	Normalize-UserSuppliedConfigData -ConfigData $ConfigData;
	
	# add members/etc. 
	[PSCustomObject]$configObject = $script:hashtableForPVConfigContents;
	
	$configObject | Add-Member -MemberType NoteProperty -Name Strict -Value $Strict -Force;
	$configObject | Add-Member -MemberType NoteProperty -Name AllowDefaults -Value $AllowDefaults -Force;
	
	$configObject | Add-Member -MemberType ScriptMethod -Name GetValue -Value ((Get-Item "Function:\Get-KeyValue").ScriptBlock) -Force;
	$configObject | Add-Member -MemberType ScriptMethod -Name SetValue -Value ((Get-Item "Function:\Set-KeyValue").ScriptBlock) -Force;
	$configObject | Add-Member -MemberType ScriptMethod -Name GetSqlInstanceNames -Value ((Get-Item "Function:\Get-SqlInstanceNames").ScriptBlock) -Force;
	$configObject | Add-Member -MemberType ScriptMethod -Name GetObjectInstanceNames -Value ((Get-Item "Function:\Get-ObjectInstanceNames").ScriptBlock) -Force;
	
	# assign as global/intrinsic: 
	$global:PVConfig = $configObject;
}