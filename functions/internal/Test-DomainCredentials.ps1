Set-StrictMode -Version 1.0;

function Test-DomainCredentials {
	param (
		[Parameter(Mandatory)]
		[PSCredential]$DomainCreds
	);
	
	try {
		$username = $DomainCreds.UserName;
		$password = $DomainCreds.GetNetworkCredential().Password;
		
		$CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName;
		$test = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain, $username, $password);
		
		return ($null -ne $test);
	}
	catch {
		return $false;
	}
}