Set-StrictMode -Version 1.0;

function Get-DirectoryPermissionsSummary {
	
	param (
		[Parameter(Mandatory)]
		[string]$Directory
	);
	
	if (-not (Test-Path $Directory)) {
		return $null;
	}
	
	(Get-Acl $Directory).Access | Select-Object -Property @{
		Name = 'Access'; Expression = "FileSystemRights";
	}, @{
		Name = "Type"; Expression = "AccessControlType";
	}, @{
		Name = "Account"; Expression = "IdentityReference";
	};
}