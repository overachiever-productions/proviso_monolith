﻿Set-StrictMode -Version 1.0;

filter Get-SqlServerInstanceMajorVersion {
	param (
		[string]$Instance = "MSSQLSERVER"
	);
	
	$instances = Get-ExistingSqlServerInstanceNames;
	if ($instances -notcontains $Instance) {
		throw "Target SQL Server Instance: [$Instance] not found/installed.";
	}
	
	
	$data = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\').$Instance;
	if ($null -eq $data) {
		throw "SQL Server Instance $Instance not found or not installed.";
	}
	
	[string[]]$parts = $data.split('.');
	
	$parts[0].Replace("MSSQL", "");
}