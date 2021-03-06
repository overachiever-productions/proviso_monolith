Set-StrictMode -Version 1.0;

function Grant-SqlServerPermissionsToDirectories {
	
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string[]]$TargetDirectories,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$SqlServiceAccountName = "NT SERVICE\MSSQLSERVER"
	);
	
	foreach ($targetDirectory in $TargetDirectories) {
		Grant-SqlServicePermissionsToDirectory -TargetDirectory $targetDirectory -SqlServiceAccountName $SqlServiceAccountName;
	}
}