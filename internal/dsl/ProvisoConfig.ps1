Set-StrictMode -Version 1.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Assign -ProvisoRoot "\\storage\Lab\proviso\";
	Target "\\storage\lab\proviso\definitions\PRO\PRO-197.psd1";

	#$PVConfig.GetValue("Host.NetworkDefinitions.VMNetwork.IpAddress");
	#$PVConfig.SetValue("Host.NetworkDefinitions.VMNetwork.IpAddress", "10.10.10.10/16");
	#$PVConfig.GetValue("Host.NetworkDefinitions.VMNetwork.IpAddress");
	#$fileCount = $PVConfig.GetValue("SqlServerInstallation.MSSQLSERVER.Setup.SqlTempDbFileCount");

	#$PVConfig.GetValue("Host.NetworkDefinitions.BilboNetwork.InterfaceAlias");

	#$PVConfig.GetValue("ExpectedDirectories.X3.RawDirectories");
	#$PVConfig.GetValue("ExpectedDirectories.MSSQLSERVER.RawDirectories");
	#$PVConfig.GetValue("ExpectedDirectories.RawDirectories");
	
	#$PVConfig.GetGroupNames("Host.LocalAdministrators");

	#$PVConfig.GetGroupNames("ExpectedDirectories");
	
	#$PVConfig.GetValue("ExpectedDirectories.MSSQLSERVER.VirtualSQLServerServiceAccessibleDirectories");

	$PVConfig.GetValue("Admindb.RestoreTestJobs.JobName");
	$PVConfig.GetValue("Admindb.MSSQLSERVER.RestoreTestJobs.JobName");

#>


[PSCustomObject]$global:PVConfig = $null;

filter Get-ProvisoConfigValueByKey {
	# NOTE: $Config here can be $this (current config) OR it could be the list of DEFAULTS. 
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$Config,
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

filter Set-ProvisoConfigValue {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Key,
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Value
	);
	
	$keys = $Key -split "\.";
	$output = $null;
	switch ($keys.Count) {
		1 {
			$this.($keys[0]) = $Value;
		}
		2 {
			$this.($keys[0]).($keys[1]) = $Value;
		}
		3 {
			$this.($keys[0]).($keys[1]).($keys[2]) = $Value;
		}
		4 {
			$this.($keys[0]).($keys[1]).($keys[2]).($keys[3]) = $Value;
		}
		5 {
			$this.($keys[0]).($keys[1]).($keys[2]).($keys[3]).($keys[4]) = $Value;
		}
		default {
			throw "Invalid Key. Too many key segments defined.";
		}
	}
}

filter Get-ConfigInstanceNames {
	#region
	#
	#	NOTE: 
	#		This current implementation is fairly brute-force (i.e., not very elegant). 
	#			BUT, it's key to determining WHICH SQL Server Instance names can be used at various points within the config. 
	#	
	#	LOGIC: 
	#		> Assume that there was a REQUIRED config node (probably up at the top of the config) that REQUIRED a definition of 
	#		which SQL Server Instances could/would be addressed within the givin config. 
	#		> In most cases, this'd just have "MSSQLSERVER" as the only instance. 
	#		But, there might be instances where it'd be "NamedInstanceX" or the much less-frequent scenario of something like: "DEV2","DEV7", "ETC". 
	#		> IF the above were true, then we'd easily know which instances to account for. 
	#		> But, forcing Proviso users to explicitly define which instances they were targeting would suck - even (or possibly especially) if/when
	#		this value could/would be 'defaulted' to "MSSQLSERVER" as that'd address 95% of scenarios out of the gate. (The remaining 5% would be
	#		a real pain in the butt in this case, though.)
	#		> So... instead of the above, the logic in this func assumes 2 things:
	#			> 1. any/all instances that can be targeted will HAVE to be defined in SqlInstallation. 
	#				(I may find that it makes sense to change this later on. And, if I do, i could, in theory, passy in different 'blocks'
	#					to work against INSTEAD of SqlInstallation - in which case, I'd HAVE to look for known-good/required-ish child-keys PER different block type)
	#			> 2. SqlExePath and Setup are going to be 'known' entity/child-keys. 
	#
	#		> and, with the above, it's possible to 'suss-out' 3 potential scenarios/use-cases/outcomes: 
	#			A. There is NO explicit SQL Server instance defined (i.e., "MSSQLSERVER" is the intended/implicit target). 
	#			B. MSSQLSERVER is EXPLICITLY defined as a target. 
	#			C. One or more OTHER (non-MSSQLSERVER/non-default-instance) named instances are the target. 
	#				As in: if the scenario is not Scenario/Outcome A, and it's NOT scenario/outcome B, then it HAS to be outcome C. 
	#
	#			Er, well: _ALL_ of the above is true except: C is NOT mutually exclusive to BOTH A and B. It's mutually exclusive to A, but B & C can both be true. 
	#				And, the logic/implementation BELOW accounts for A or B|C (i.e., 1 more or more NAMED instances CAN exist along side MSSQLSERVER instance.)
	# 	
	# 	TODO: 
	# 		Look at 'weaponizing' the logic below - as in, there are 3x virtually identical checks - the only real differences are:
	# 			the PATH for what we're testing. 
	# 		As such, a bit of weaponization would 
	# 			- would remove a lot of the tedious if/else crap in here (by collapsing down logic to path checks and a 'func' or whatever that evaluated 'parent', then .SqlExePath, then .Setup, etc.)
	#			- allow for option to check for OTHER config 'blocks' (surfaces) OTHER than just "SqlInstallation" - i.e., pass in, say, "SqlDirectories" and the 1-2x 'nodes' to use for validation
	# 					at which point, I could get SQL Server Instance Names PER each "surface" area - meaning that it COULD/WOULD be possible to define differences from one surface to the next. 
	# 				NOT sure this would 'help' or even be good... but, if I 'need' this, that'd be the way to go.
	#endregion
	$sqlInstallationBlock = Get-ProvisoConfigValueByKey -Config $this -Key "SqlServerInstallation";
	
	try {
		# Scenario A:
		$test = $sqlInstallationBlock.SqlExePath; # check for implicit MSSQLSERVER as solitary instance... 
		if ($null -ne $test) {
			$setupNode = $sqlInstallationBlock.Setup; # looks good, but let's verify first:
			if ($setupNode -is [hashtable]) {
				return @("MSSQLSERVER");
			}
		}
		
		# Scenario B:
		$instances = @();
		$test = $sqlInstallationBlock.MSSQLSERVER.SqlExePath;
		if ($null -ne $test) {
			$setupNode = $sqlInstallationBlock.MSSQLSERVER.Setup; # looks good, but let's verify first:
			if ($setupNode -is [hashtable]) {
				#return @("MSSQLSERVER");
				$instances += "MSSQLSERVER";
			}
		}
		
		# Scenario C:
		foreach ($kvp in $sqlInstallationBlock.GetEnumerator()) {
			$key = $kvp.Key;
			if ("MSSQLSERVER" -ne $key) {
				$test = $sqlInstallationBlock.$key.SqlExePath;
				if ($null -ne $test) {
					$setupNode = $sqlInstallationBlock.$key.Setup; # looks good, but let's verify first:
					if ($setupNode -is [hashtable]) {
						$instances += $key;
					}
				}
			}
		}
		
		if ($instances.Count -gt 0) {
			return $instances;
		}
	}
	catch {
		throw "Error Determining SQL Server Instance Names from Current Proviso Config. Please double-check config (.psd1) file. `rEXCEPTION: $_  `r`t$($_.ScriptStackTrace) ";
	}
	
	throw "Error Determining SQL Server Instance Names from Current Proviso COnfig. Please verify config (.psd1) structure/values.";
}

filter Get-ProvisoConfigValue {
	param (
		[ValidateNotNullOrEmpty()] 	# TODO: either see if there's a way to get ValidateNotNullOrEmpty to throw a 'friendly' error message, or implement one of my own...
		[string]$Key
	);
	
	# TODO: ExtendedEvents and AvailabilityGroups are BOTH 'instance' AND 'sqlinstance'.
	$output = Get-ProvisoConfigValueByKey -Config $this -Key $Key;
	
	if (-not ($this.AllowDefaults) -or ($null -ne $output)) {
		return $output;
	}
	
	#region Scope/Dev Notes
	# At this point, the EXACT key specified wasn't found AND Target allows GlobalDefaults. 
	#  	Types (families) of defaults we might find at this point: 
	#   A. Scalar Defaults. 
	# 		> Expected/Core defaults - i.e., something hard-coded like: "Host.RequiredPackages.NetFxForPre2016InstancesRequired" = $false;
	# 				in which case, we just return the hard-coded value.
	# 		> Ditto - but DYNAMIC - e.g., (well, actually, don't currently have an example - all {~DYNAMIC~} are currently SQL instances?)... 
	# 				in which case... there should be a helper or some other logic to 'compute'/define a 'default' based on something within 
	# 				the environment - and then we simply return that value (i.e., kind of like 'hard-coded' but 'dynamic').
	#       > Ditto - but DEFAULT_PROHIBITED. like "Host.TargetServer" = "{~DEFAULT_PROHIBITED~}" -
	# 				in which case: throw... 
	# 	B. Instance-Scoped-Defaults - i.e., keys with the ability to have an {~ANY~} within the path... 
	# 			Examples: disks, network adapters, data-collector-sets. 
	# 		These, in turn, can then have 3x different default 'types':
	#  			> scalar or 'hard-coded' - i.e., just like NORMAL hard-coded values, but with an {~ANY~} in the key name that gets 'handled'. 
	# 			> dynamic - just as in 'group A', but will be part of a specific instance... 
	# 					examples: block-size for a disk - 64K (as in, for any/all disks, if .psd1 doesn't specify a block size, then ... 64K is the default.)
	# 			> prohibited - as above, but... a case where a default doesn't make sense.
	# 					examples: subnet mask/network-size for an IP or ... volumeLetter for a disk. 
	#   C. SqlServer-Instance-Scoped-Defaults. 
	# 			Virtually identical to 'family B' - but instead of {~ANY~} these will be {~SQLINSTANCE~} ... denoting an allowable SQL Server instance. 
	# 		So, again, 3x types of values: 
	# 			> hard-coded (but by SqlInstance) - example: "SqlServerConfiguration.{~SQLINSTANCE~}.DisableSaLogin" = $false (by default per/for every instance... )
	# 			> dynamic (but by SqlInstance) - example: "SqlServerInstallation.{~SQLINSTANCE~}.ServiceAccounts.SqlServiceAccountName" = ... dynamic: NT SERVICE\xxx (by virtue of instance name... )
	# 			> prohibited (per/for SqlInstance) - example: "SqlServerInstallation.{~SQLINSTANCE~}.SqlExePath" - there can't be a default for this, HAS to be specified... 
	
	#  Finally, if/when a {~SQLINSTANCE~} is detected, MSSQLSERVER will be implied unless an explicit value for another instance name exists. 
	#endregion
	
	# Start by Looking for simple, hard-coded matches: 
	$output = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $Key;
	
	# Check for INSTANCE keys (i.e., non-SQL Server Instances that allow wildcards... disks, network adapters, etc.)
	[string]$instanceName = $null;
	[string]$sqlInstanceName = $null;
	if ($null -eq $output) {
		$match = [regex]::Matches($Key, '(Host\.NetworkDefinitions|Host\.ExpectedDisks|ExpectedShares|DataCollectorSets)\.(?<instanceName>[^\.]+)');
		if ($match) {
			$instanceName = ($match[0].Groups['instanceName']).Value;
			$anyKey = $Key -replace $instanceName, "{~ANY~}";
			
			$output = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $anyKey;
			if ($output -is [hashtable]) {
				$output = $null; # don't allow export of an entire key GROUP... 
			}
			
			if ("{~PARENT~}" -eq $output) {
				$output = $instanceName;
			}
		}
		
		return $output;
	}
	
	# Check for a SQL Server Instance Key - i.e., a key that REQUIREs a SqlServerInstance - or that can use {~SQLINSTANCE~}... 
	if ($null -eq $output) {
		# MKC: Holy Crap. What an UTTER mess this ended up being... 
		# 	there are 2 locations to check for a match: actual/explicit config.
		#  and there are 2 paths to check: explicit SQLInstanceName or ImplicitSqlInstanceName
		#  		that yields at LEAST 4x permutations in the code... 
		#  		which is made worse by the fact that there are named instances, and MSSQLSERVER (implicit/explicit)... 
		# 			and then... {~SQLINSTANCE~} vs ... or not... 
		# 		so, the whole thing is a nightmare - and obscenely complicated.  
		$match = [regex]::Matches($Key, '(ExpectedDirectories|SqlServerInstallation|SqlServerConfiguration|SqlServerPatches|Admindb|ExtendedEvents|ResourceGovernor|AvailabilityGroups|CustomSqlScripts)\.', 'IgnoreCase');
		if ($match) {
			[string[]]$configDefinedInstanceNames = Get-ConfigInstanceNames;
	
			if (($configDefinedInstanceNames.Count -eq 1) -and ("MSSQLSERVER" -eq $configDefinedInstanceNames[0])) {
				if ($Key -like '*MSSQLSERVER*') {
					# NOTE: this is a legit scenario to address - but I added this logic 'back in after the fact' - i.e., this is a bit of a hack... 
					$implicitKey = $Key -replace 'MSSQLSERVER\.', '';
					$output = Get-ProvisoConfigValueByKey -Config $this -Key $implicitKey;
					
					if ($null -eq $output) {
						$wildcardKey = $Key -replace 'MSSQLSERVER\.', '{~SQLINSTANCE~}.';
						$output = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $wildcardKey;
					}
					
					if ($null -ne $output) {
						return $output;
					}
				}
	
				# attempt to extract implicit (non-named) values first, and, if null, then grab by MSSQLSERVER instance:
				$output = Get-ProvisoConfigValueByKey -Config $this -Key $Key;
				if ($null -eq $output) {
					$output = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $Key;
				}
				
				if ($null -eq $output) {
					$keyParts = $Key -split '\.';
					$newKey = $keyParts[0] + '.' + "MSSQLSERVER" + ($Key -replace $keyParts[0], "")
					$output = Get-ProvisoConfigValueByKey -Config $this -Key $newKey;
					
					if ($null -eq $output) {
						# if there wasn't an explicit key, look for a default - but, in this case, look for a 'generic' SqlInstance value:
						$newKey = $newKey -replace "MSSQLSERVER", "{~SQLINSTANCE~}";
						$output = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $newKey;
					}
				}
				return $output;
			}
			else {
				$match = [regex]::Matches($Key, '(ExpectedDirectories|SqlServerInstallation|SqlServerConfiguration|SqlServerPatches|AdminDb|ExtendedEvents|ResourceGovernor|AvailabilityGroups|CustomSqlScripts)\.(?<sqlInstanceName>[^\.]+)', 'IgnoreCase');
				if ($match) {
					$sqlInstanceName = $match[0].Groups['sqlInstanceName'];
					
					Write-Host "Explicit and for InstanceName: $sqlInstanceName"
					
				}
			}
		}
		else {
			throw "Proviso Framework Error. Invalid Key: [$Key] detected in `$PVConfig.GetValue().";
		}
	}
	
	if ($null -eq $output) { # TODO: MIGHT make sense to THROW here if -Strict... 
		return $null; # no matches found - i.e., no hard-coded matches, no 'instance' matches, and no 'sql instance' matches - effectively, an invalid key. 
	}
	
	if ("{~DEFAULT_PROHIBITED~}" -eq $output) {
		throw "Configuration Exception. An explicit Configuration value for Key [$Key] was not defined - and Default values for this key are NOT allowed.";
	}
	
	if ("{~DYNAMIC~}" -eq $output) {
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
					$parts = $Key -split '\.';
					$directoryName = $parts[$parts.length - 1];
					
					return Get-SqlServerDefaultDirectoryLocation -InstanceName $instanceName -SqlDirectory $directoryName;
				}
				else {
					throw "Proviso Framework Error. Non-Default SQL Server Instance for SQL Server Default Directories threw an exception.";
				}
			}
			{ $_ -like "*ServiceAccounts*"} {
				$match = [regex]::Matches($Key, 'SqlServerInstallation\.(?<instanceName>[^\.]+).', 'IgnoreCase');
				if ($match) {
					$instanceName = $match[0].Groups['instanceName'];
					$parts = $Key -split '\.';
					$serviceName = $parts[$parts.length - 1];
					
					return Get-SqlServerDefaultServiceAccount -InstanceName $instanceName -AccountType $serviceName;
				}
				else {
					throw "Proviso Framework Error. Non-Default SQL Server Instance for SQL Server Default Directories threw an exception.";
				}
			}			
			default {
				throw "Proviso Framework Error. Invalid {~DYNAMIC~} default provided for key: [$Key].";
			}
		}
	}
	
	return $output;
}

filter Validate-ConfigKey {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Key
	);
	
	$exists = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $Key;
	if ($null -eq $exists) {
		return $false; 
	}
	
	return $exists;
	
	# NOTE: this can't/won't be able to target the actual $PVConfig/$this - it HAS to work against $ConfigDefaults object.
	# and, while there are effectively 3x 'families' * 3x types (i.e., 9 combinations) of keys that could work, we're ONLY
	# 	looking for a match - be it a hard-coded match, a dynamic match, or EVEN a default-prohibitied match. 
}

filter Get-ProvisoConfigGroupNames {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$GroupKey,
		[string]$OrderByKey
	);
	
	# do validations/etc. 
	$decrementKey = [int]::MaxValue;
	
	$block = $this.GetValue($GroupKey);
	$keys = $block.Keys;
	
	if ($OrderByKey) {
		
		$prioritizedKeys = New-Object "System.Collections.Generic.SortedDictionary[int, string]";
		
		foreach ($key in $keys) {
			$orderingKey = "$GroupKey.$key.$OrderByKey";
			
			$priority = Get-ProvisoConfigValueByKey -Key $orderingKey -Config $PVConfig;
			if (-not ($priority)) {
				$decrementKey = $decrementKey - 1;
				$priority = $decrementKey;
			}
			
			$prioritizedKeys.Add($priority, $key);
		}
		
		$keys = @();
		foreach ($orderedKey in $prioritizedKeys.GetEnumerator()) {
			$keys += $orderedKey.Value;
		}
	}
	
	# HACK
	$keys = Scrub-Keys -GroupKey $GroupKey -Keys $keys;
	return $keys;
}

filter Scrub-Keys {
	param (
		[string]$GroupKey,
		[object[]]$Keys
	);
	
	if (($null -eq $Keys) -or ($Keys.Count -lt 1)) {
		return $Keys;
	}
	
	switch ($GroupKey) {
		"ExpectedDirectories" {
			if ($Keys -contains "VirtualSqlServerServiceAccessibleDirectories") {
				return @("MSSQLSERVER");
			}
		}
#		"ExpectedShares" {
#			if($Keys -contains "S")
#		}
	}
	
	return $Keys;
}

filter Set-ConfigTarget {
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$ConfigData,
		[switch]$Strict = $false,
		[switch]$AllowDefaults = $true,
		[Switch]$Force = $false
	);
	
	[PSCustomObject]$Config = $ConfigData;
	if ($Strict) {
		if ($null -eq $Config.Host.TargetServer) {
			throw "-Strict set to TRUE, but Configuration.Host.TargetServer value not set or found.";
		}
		
		$currentHostName = [System.Net.Dns]::GetHostName();
		if ($currentHostName -ne $Config.Host.TargetServer) {
			throw "-Strict is set to TRUE, and Current Host Name of [$currentHostName] does not match [$($Config.Host.TargetServer)].";
		}
	}
	
	[bool]$addMembers = $true;
	if (($Config.PSObject.Properties.Name -eq "MembersConfigured") -and (-not ($Force))) {
		$addMembers = $false;
	}
	
	if ($addMembers) {
		Add-Member -InputObject $Config -MemberType NoteProperty -Name MembersConfigured -Value $true -Force;
		Add-Member -InputObject $Config -MemberType NoteProperty -Name Strict -Value $Strict -Force;
		Add-Member -InputObject $Config -MemberType NoteProperty -Name AllowDefaults -Value $AllowDefaults -Force;
		
		[ScriptBlock]$setValue = (Get-Item "Function:\Set-ProvisoConfigValue").ScriptBlock;
		[ScriptBlock]$getValue = (Get-Item "Function:\Get-ProvisoConfigValue").ScriptBlock;
		[ScriptBlock]$getGroupNames = (Get-Item "Function:\Get-ProvisoConfigGroupNames").ScriptBlock;
		
		Add-Member -InputObject $Config -MemberType ScriptMethod -Name SetValue -Value $setValue;
		Add-Member -InputObject $Config -MemberType ScriptMethod -Name GetValue -Value $getValue;
		Add-Member -InputObject $Config -MemberType ScriptMethod -Name GetGroupNames -Value $getGroupNames;
	}
	
	$global:PVConfig = $Config;
}

#region old code
#filter Get-ProvisoConfigDefault {
#	param (
#		[Parameter(Mandatory)]
#		[ValidateNotNullOrEmpty()]
#		[string]$Key,
#		[switch]$ValidateOnly = $false # validate vs return values... 
#	);
#	
#	$defaultValue = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $Key;
#	# NOTE: this is kind of BS... i have to put the STRING to the left in these evaluations - otherwise a value of $true will trigger as TRUE and complete the -eq ... 
#	if ("{~DEFAULT_PROHIBITED~}" -eq $defaultValue) {
#		if ($ValidateOnly) {
#			return $true;
#		}
#		else {
#			$defaultValue = $null;
#		}
#	}
#	
#	if ("{~DYNAMIC~}" -eq $defaultValue) {
#Write-Host "DYNAMIC SWITCH on Key: $Key"
#		switch ($Key) {
#			{ $_ -like '*SqlTempDbFileCount' } {
#				$coreCount = Get-WindowsCoreCount;
#				if ($coreCount -le 4) {
#					return $coreCount;
#				}
#				return 4;
#			}
#			{ $_ -like "*SqlServerInstallation*SqlServerDefaultDirectories*" } {
#				$match = [regex]::Matches($Key, 'SqlServerInstallation\.(?<instanceName>[^\.]+).');
#
#				if ($match) {
#					$instanceName = $match[0].Groups['instanceName'];
#					$parts = $Key -split '\.';
#					$directoryName = $parts[$parts.length - 1];
#					
#					return Get-SqlServerDefaultDirectoryLocation -InstanceName $instanceName -SqlDirectory $directoryName;
#				}
#				else {
#					throw "Proviso Framework Error. Non-Default SQL Server Instance for SQL Server Default Directories threw an exception.";
#				}
#			}
#			{ $_ -like "*ServiceAccounts*"} {
#	Write-Host "got here"
#				$match = [regex]::Matches($Key, 'SqlServerInstallation\.(?<instanceName>[^\.]+).');
#				if ($match) {
#					$instanceName = $match[0].Groups['instanceName'];
#					$parts = $Key -split '\.';
#					$serviceName = $parts[$parts.length - 1];
#					
#					return Get-SqlServerDefaultServiceAccount -InstanceName $instanceName -AccountType $serviceName;
#				}
#				else {
#					throw "Proviso Framework Error. Non-Default SQL Server Instance for SQL Server Default Directories threw an exception.";
#				}
#			}
#			default {
#				throw "Proviso Framework Error. Invalid {~DYNAMIC~} default provided for key: [$Key].";
#			}
#		}
#	}
#	
#	if ($null -ne $defaultValue) {
#		return $defaultValue;
#	}
#	
#	# Non-SQL-Instance Partials (pattern):
#	$match = [regex]::Matches($Key, '(Host\.NetworkDefinitions|Host\.LocalAdministrators|Host\.ExpectedDisks|ExpectedShares|AvailabilityGroups)\.(?<partialName>[^\.]+)');
#	if ($match) {
#		$partialName = $match[0].Groups['partialName'];
#		
#		if (-not ([string]::IsNullOrEmpty($partialName))) {
#			$nonSqlPartialKey = $Key.Replace($partialName, '{~ANY~}');
#			
#			$defaultValue = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $nonSqlPartialKey;
#			
#			if ($null -ne $defaultValue) {
#				if ($ValidateOnly -and ($defaultValue.GetType() -in "hashtable", "System.Collections.Hashtable", "system.object[]")) {
#					return $defaultValue;
#				}
#				
#				if ($defaultValue -eq "{~PARENT~}") {
#					$defaultValue = $partialName;
#				}
#				
#				if ($null -ne $defaultValue) {
#					return ($defaultValue).Value;
#				}
#			}
#			
#			if ($ValidateOnly) {
#				return ($partialName).Value;
#			}
#		}
#	}
#	
#	# Address wildcards: 
#	# 	NOTE: I COULD have used 1x regex (that combined instance AND other (above) details), but went with SRP (i.e., each regex is for ONE thing):
#	$match = [regex]::Matches($Key, '(ExpectedDirectories|SqlServerInstallation|SqlServerConfiguration|SqlServerPatches|AdminDb|ExtendedEvents|ResourceGovernor|CustomSqlScripts)\.MSSQLSERVER');
#	# TODO: dont' think the regex above accounts for anything OTHER THAN JUST MSSQLSERVER as the named instance... 
#Write-Host "Down here - in SQL Stuff."	
#	if ($match) {
#		$keyWithoutDefaultMSSQLServerName = $Key.Replace('MSSQLSERVER', '{~ANY~}');
#		$output = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $keyWithoutDefaultMSSQLServerName;
#		
#write-host "non-named instances: $output"		
#		
#		if ($null -ne $output) {
#			return $output;
#		}
#	}
#	
#	return $null;
#}


#filter Get-ProvisoConfigCompoundValues {
#	param (
#		[Parameter(Mandatory)]
#		[PSCustomObject]$Config,
#		[Parameter(Mandatory)]
#		[string]$FullCompoundKey,
#		[switch]$OrderDescending = $false
#	);
#	
#	$keys = Get-ProvisoConfigValueByKey -Config $Config -Key $FullCompoundKey;
#}

#endregion
