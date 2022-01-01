﻿Set-StrictMode -Version 1.0;

filter Get-SqlServerDefaultDirectoryLocation {
	
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$InstanceName,
		[Parameter(Mandatory)]
		[PSCustomObject]$SqlDirectory
	);
	
	# vNEXT can, eventually allow for default directories in the form of "D:\<instanceName>\<directoryName>" and if/when the <instanceName> is MSSQLSERVER... then replace <instanceName> with "" or whatever so that we just get "D:\<directoryName>"
	#  		otherwise, we'd get, say: "D:\X3\SQLData" and so on... 
	
	switch ($SqlDirectory) {
		
		"SqlDataPath" {
			return "D:\SQLData";
		}
		"SqlLogsPath" {
			return "D:\SQLData";
		}
		"SqlBackupsPath" {
			return "D:\SQLBackups";
		}
		"TempDbPath" {
			return "D:\SQLData";
		}
		"TempDbLogsPath" {
			return "D:\SQLData";
		}
	}
}