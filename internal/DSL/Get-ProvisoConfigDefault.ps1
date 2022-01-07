Set-StrictMode -Version 1.0;

# REFACTOR: https://overachieverllc.atlassian.net/browse/PRO-178

filter Get-ProvisoConfigDefault {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Key,
		[switch]$ValidateOnly = $false  # validate vs return values... 
	);
	
	$defaultValue = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $Key;
	
	# NOTE: this is kind of BS... i have to put the STRING to the left in these evaluations - otherwise a value of $True will trigger as TRUE and complete the -eq ... 
	if ("{~DEFAULT_PROHIBITED~}" -eq $defaultValue) {
		if ($ValidateOnly) {
			return $true;
		}
		else {
			$defaultValue = $null;
		}
	}
	
	if ("{~DYNAMIC~}" -eq $defaultValue) {
		switch ($Key) {
			{ $_ -like '*SqlTempDbFileCount' } {
				$coreCount = Get-WindowsCoreCount;
				if ($coreCount -le 4) {
					return $coreCount;
				}
				return 4;
			}
			default {
				throw "Proviso Framework Error. Invalid {~DYNAMIC~} default provided for key: [$Key].";
			}
		}
	}
	
	if ($null -ne $defaultValue) {
		return $defaultValue;
	}

	# Non-SQL-Instance Partials (pattern):
	$match = [regex]::Matches($Key, '(Host\.NetworkDefinitions|Host\.ExpectedDisks|ExpectedShares|AvailabilityGroups)\.(?<partialName>[^\.]+)');
	if ($match) {
		$partialName = $match[0].Groups['partialName'];
		
		if (-not ([string]::IsNullOrEmpty($partialName))) {
			$nonSqlPartialKey = $Key.Replace($partialName, '{~ANY~}');
		
			$defaultValue = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $nonSqlPartialKey;
			
			if ($null -ne $defaultValue) {
				if ($ValidateOnly -and ($defaultValue.GetType() -in "hashtable", "System.Collections.Hashtable", "system.object[]")) {
					return $defaultValue;
				}
				
				if ($defaultValue -eq "{~PARENT~}") {
					$defaultValue = $partialName;
				}
				
				if ($null -ne $defaultValue) {
					return ($defaultValue).Value;
				}
			}
			
			if ($ValidateOnly) {
				return ($partialName).Value;
			}
		}
	}
	
	# Address wildcards: 
	# 	NOTE: I COULD have used 1x regex (that combined instance AND other details), but went with SRP (i.e., each regex is for ONE thing):
	$match = [regex]::Matches($Key, '(ExpectedDirectories|SqlServerInstallation|SqlServerConfiguration|SqlServerPatches|AdminDb|ExtendedEvents|ResourceGovernor|CustomSqlScripts)\.MSSQLSERVER');
	if ($match) {
		$keyWithoutDefaultMSSQLServerName = $Key.Replace('MSSQLSERVER', '{~ANY~}');
		$output = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $keyWithoutDefaultMSSQLServerName;
		
		if ($null -ne $output) {
			return $output;
		}
	}
	
	return $null;
}