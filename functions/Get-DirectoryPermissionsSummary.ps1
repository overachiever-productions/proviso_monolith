Set-StrictMode -Version 1.0;

function Get-DirectoryPermissionsSummary {
	
	param (
		[string]$Directory
	);
	
	Get-Acl $Directory | Select-Object AccessToString | Format-List;
}