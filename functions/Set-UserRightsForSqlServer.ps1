Set-StrictMode -Version 1.0;

function Set-UserRightsForSqlServer {
	
	param (
		[switch]$LockPagesInMemory,
		[switch]$PerformVolumeMaintenanceTasks
	);
	
	[string]$AccountName = "NT SERVICE\MSSQLSERVER";
	
	Mount-Directory "C:\Scripts"; 
	[string]$secpolFile = "C:\Scripts\secpol.inf";
	SecEdit /export /cfg $secpolFile /areas USER_RIGHTS /quiet | Out-Null;
	
	$policy = Get-Content -Path $secpolFile;
	
	$pvmt = $policy | Select-String -Pattern "^SeManageVolumePrivilege\s*=\s*.+";
	$lpim = $policy | Select-String -Pattern "^SeLockMemoryPrivilege\s*=\s*.+";
	$nlr = $policy | Select-String -Pattern "^SeNetworkLogonRight\s*=\s*.+";
	[bool]$modified = $false;
	
	$sid = ConvertTo-WindowsSecurityIdentifier -Name $AccountName;
	
	if ($LockPagesInMemory) {
		if ([string]::IsNullOrEmpty($lpim)) {
			$policy = $policy.Replace($nlr, "$nlr`nSeLockMemoryPrivilege = *$($sid)");
		}
		else {
			if (-not ($lpim -like "*$sid*")) {
				$policy = $policy.Replace($lpim, "$lpim,*$($sid)");
			}
		}
		$modified = $true;
	}
	
	if ($PerformVolumeMaintenanceTasks) {
		if ([string]::IsNullOrEmpty($pvmt)) {
			$policy = $policy.Replace($nlr, "$nlr`nSeLockMemoryPrivilege = *$($sid)");
		}
		else {
			if (-not ($pvmt -like "*$sid*")) {
				$policy = $policy.Replace($pvmt, "$pvmt,*$($sid)");
			}
		}
		$modified = $true;
	}
	
	if($modified){
		$policy | Out-File $secpolFile -Force -Confirm:$false;
		SecEdit /configure /db secedit.sdb /cfg $secpolFile /areas USER_RIGHTS /overwrite /quiet | Out-Null;
	}
	
	Remove-Item -Path $secpolFile;
}