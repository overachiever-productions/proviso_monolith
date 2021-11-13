Set-StrictMode -Version 1.0;

filter Get-ProvisoConfigDefault {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Key,
		[switch]$ValidateOnly = $false  # validate vs return values... 
	);
	
	$defaulValue = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $Key;
	
	if ($null -ne $defaulValue) {
		if ($defaulValue -eq "{~DEFAULT_PROHIBITED~}") {
			if (-not ($ValidateOnly)){
				$defaulValue = $null;
			}
		}
	}
	
	if ($null -ne $defaulValue) {
		return $defaulValue;
	}
	
	# Non-SQL-Instance Partials (pattern):
	$match = [regex]::Matches($Key, '(Host\.NetworkDefinitions|Host\.ExpectedDisks|ExpectedShares|AvailabilityGroups)\.(?<partialName>[^\.]+)');
	if ($match) {
		$partialName = $match[0].Groups['partialName'];

		if (-not ([string]::IsNullOrEmpty($partialName))) {
			$nonSqlPartialKey = $Key.Replace($partialName, '{~ANY~}');
			
			$defaulValue = Get-ProvisoConfigValueByKey -Config $script:ProvisoConfigDefaults -Key $nonSqlPartialKey;
			
			if ($null -ne $defaulValue) {
				if ($ValidateOnly -and ($defaulValue.GetType() -in "hashtable", "System.Collections.Hashtable", "system.object[]")) {
					return $defaulValue;
				}
				
				if ($defaulValue -eq "~{PARENT}~") {
					$defaulValue = $partialName;
				}
				
				if ($null -ne $defaulValue) {
					return ($defaulValue).Value;
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