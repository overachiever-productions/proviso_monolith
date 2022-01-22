Set-StrictMode -Version 1.0;

filter Get-ConnectionInstance {
	param (
		[Parameter(Mandatory)]
		[string]$InstanceName
	);
	
	if ($InstanceName -ne "MSSQLSERVER") {
		return ".\$InstanceName";
	}
	
	return ".";
}