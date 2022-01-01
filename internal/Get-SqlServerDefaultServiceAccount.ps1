Set-StrictMode -Version 1.0;

filter Get-SqlServerDefaultServiceAccount {
	
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$InstanceName,
		[Parameter(Mandatory)]
		[PSCustomObject]$AccountType
	);
	
	# vNEXT: spin this up to use the defined SVC accounts for named-instances as well... i.e., not hard to do at all... 
	
	switch ($AccountType) {
		"SqlServiceAccountName" {
			return "NT SERVICE\MSSQLSERVER";
		}
		"AgentServiceAccountName" {
			return "NT SERVICE\SQLSERVERAGENT";
		}
		default {
			throw "Default SQL Server Service Accounts for anything other than SQL Server and SQL Server Agent are not, currently, support for anything other than MSSQLSERVER instance.";
		}
	}
}