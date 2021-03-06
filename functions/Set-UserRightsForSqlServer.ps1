Set-StrictMode -Version 1.0;

# REQUIRES: UserRights.psm1 by Tony Pombo - https://gallery.technet.microsoft.com/Grant-Revoke-Query-user-26e259b0 
# NOTE: UserRights.psm1 won't work in/against PowerShell 7 - likely won't work with Powershell either.
# 		might be, legit, time to look at creating this functionality with ... C# 
function Set-UserRightsForSqlServer {
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$AccountName = "NT SERVICE\MSSQLSERVER",
		[switch]$LockPagesInMemory,
		[switch]$PerformVolumeMaintenanceTasks
	);
	
	#$accountName = (Invoke-SqlCmd -Query "SELECT service_account FROM sys.[dm_server_services] WHERE [filename] LIKE '%sqlservr.exe%'; ").service_account;
	#$accountSID = (New-Object System.Security.Principal.NTAccount($accountName)).Translate([System.Security.Principal.SecurityIdentifier]).value
	
	# TODO: figure out some ways to better/more dynamically try to load this. 
	#   specifically, 1. see if it exists in C:\Scripts\modules first... then... 2. try the lab path and ... also, 3. allow path to be passed in as a parameter:
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