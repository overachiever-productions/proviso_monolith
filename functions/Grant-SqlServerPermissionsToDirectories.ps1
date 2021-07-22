Set-StrictMode -Version 1.0;

function Grant-SqlServerPermissionsToDirectories {
	
	# vNEXT: not even sure this is used anymore... (i.e., check ephemeral disks setup and ... Configure-SErver.ps1)
	
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string[]]$TargetDirectories,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$SqlServiceAccount = "NT SERVICE\MSSQLSERVER"
	);
	
	foreach ($target in $TargetDirectories) {
		Grant-SqlServicePermissionsToDirectory -Target $target -SqlServiceAccount $SqlServiceAccount;
	}
}