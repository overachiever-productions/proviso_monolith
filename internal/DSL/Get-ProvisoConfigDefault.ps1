Set-StrictMode -Version 1.0;

filter Get-ProvisoConfigDefault {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Key
	);
	
	$defaulValue = Get-ProvisoConfigValueByKey -Config $script:Proviso_Config_Defaults -Key $Key;
	if ($null -ne $defaulValue) {
		return $defaulValue;
	}
	
	# Non-SQL-Instance Partials (pattern):
	$match = [regex]::Matches($Key, '(Host\.NetworkDefinitions|Host\.ExpectedDisks|ExpectedShares|AvailabilityGroups)\.(?<partialName>[^\.]+)');
	if ($match) {
		$partialName = $match[0].Groups['partialName'];
		if (-not ([string]::IsNullOrEmpty($partialName))) {
			$nonSqlPartialKey = $Key.Replace($partialName, '{~ANY~}');
			
			$defaulValue = Get-ProvisoConfigValueByKey -Config $script:Proviso_Config_Defaults -Key $nonSqlPartialKey;
			if ($null -ne $defaulValue) {
				if ($defaulValue -eq "~{PARENT}~") {
					$defaulValue = $partialName;
				}
				
				return $defaulValue;
			}
		}
	}
	
	# NOTE: ARGUABLY, I could potentially combine 'non-sql-instance-names' (SqlDataDisk, VM Network, etc. ) amd sql-instance-names (MSSQLSERVER, TEST, etc)
	#   into a big/single REGEX that does one and/or the other ... 
	#   BUT: having 2x fairly-duplicated-ish bits of logic keeps the complexity a LOT simpler. i.e., check for x. if not x, check for y. the end. 
	$match = [regex]::Matches($Key, '(ExpectedDirectories|SqlServerInstallation|SqlServerConfiguration|SqlServerPatches|AdminDb|ExtendedEvents|ResourceGovernor|CustomSqlScripts)\.MSSQLSERVER');
	if ($match) {
		$keyWithoutDefaultMSSQLServerName = $Key.Replace('MSSQLSERVER', '{~ANY~}');
		$output = Get-ProvisoConfigValueByKey -Config $script:Proviso_Config_Defaults -Key $keyWithoutDefaultMSSQLServerName;
		
		if ($null -ne $output) {
			return $output;
		}
	}
	
	return $null;
}