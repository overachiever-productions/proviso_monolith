Set-StrictMode -Version 1.0;

function Import-PerformanceCounterData {
	
	# some damned hell STUPID error with (Get-ChildItem -Path ... and the -File switch). 
	# 		i can call this until i'm blue in the face, manually, but it won't work in this script for some reason.
	
	# looks like it's an issue with powershell accepting paths/folders with . in the name (i.e., E:\Data\.scratch\ throws problems?)	
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$ParentDirectory,
		[Parameter(Mandatory = $true)]
		[string]$HostFilter,
		[Parameter(Mandatory = $true)]
		[string]$TargetTableName
	);
	
	$files = (Get-ChildItem -Path $ParentDirectory -File -Recurse) | Where-Object {
		$_.PSParentPath -match $HostFilter
	} | Select-Object FullName;
	#Write-Host $files;
	
	Import-DbaCsv -Path $files -SqlInstance DEV -SqlCredential (Get-Credential sa) -Database PerfCounters -Table $TargetTableName -AutoCreateTable;
	
}


#
#function Import-PerformanceCounters {
#	param (
#		[Parameter(Mandatory = $true)]
#		[string]$ParentDirectory,
#		[Parameter(Mandatory = $true)]
#		[string]$HostFilter,
#		[Parameter(Mandatory = $true)]
#		[string]$TargetTableName
#	);
#	
#	$files = (Get-ChildItem -Path $ParentDirectory -File -Recurse) | Where-Object {
#		$_.PSParentPath -match $HostFilter
#	} | Select-Object FullName;
#	#Write-Host $files;
#	
#	Import-DbaCsv -Path $files -SqlInstance "dev.sqlserver.id" -SqlCredential (Get-Credential sa) -Database PerfCounters -Table $TargetTableName -AutoCreateTable;
#}
#
#Import-PerformanceCounters -ParentDirectory "E:\import" -HostFilter "NA1SQL2" -TargetTableName "October2020_NA2";