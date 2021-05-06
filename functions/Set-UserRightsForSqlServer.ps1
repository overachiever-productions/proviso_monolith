Set-StrictMode -Version 1.0;

# REQUIRES: UserRights.psm1 by Tony Pombo - https://gallery.technet.microsoft.com/Grant-Revoke-Query-user-26e259b0 
# NOTE: UserRights.psm1 won't work in/against PowerShell 7 - likely won't work with Powershell either.
# 		might be, legit, time to look at creating this functionality with ... C# 
function Set-UserRightsForSqlServer {
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$AccountName = "NT SERVICE\MSSQLSERVER",
		[Parameter(Mandatory = $true)]
		[string]$UserRightsPsm1Path,
		[switch]$LockPagesInMemory,
		[switch]$PerformVolumeMaintenanceTasks
	);
	
	Import-Module "\\storage.overachiever.net\Lab\scripts\modules\UserRights.psm1" -Force;
	
	$accountSID = ConvertTo-WindowsSecurityIdentifier -DomainUser $AccountName;
	Write-Host $accountSID;
	
	return;
	
	if ($LockPagesInMemory) {
		Grant-UserRight -Account $accountSID -Right SeLockMemoryPrivilege;
	}
	
	if ($PerformVolumeMaintenanceTasks) {
		Grant-UserRight -Account $accountSID -Right SeManageVolumePrivilege; # handled via .INI / Setup as of 2017+	
	}
}