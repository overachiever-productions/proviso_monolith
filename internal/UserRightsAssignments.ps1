Set-StrictMode -Version 1.0;

filter Get-UserRightForSqlServer {
	param (
		[Parameter(Mandatory)]
		$InstanceName,
		[ValidateSet("PVMT", "LPIM")]
		[string]$UserRight
	);
	
	[string]$accountName = Get-SqlServerDefaultServiceAccount -InstanceName $InstanceName -AccountType "SqlServiceAccountName";
	
	$sid = ConvertTo-WindowsSecurityIdentifier -Name $accountName;
	$policy = Get-UserRightsPolicy;
	
	$rightsPattern = "^SeManageVolumePrivilege\s*=\s*.+";
	if ($UserRight -eq "LPIM") {
		$rightsPattern = "^SeLockMemoryPrivilege\s*=\s*.+";
	}
	
	$right = $policy | Select-String -Pattern $rightsPattern;
	
	if ($right) {
		if ($right -like "*$sid*") {
			return $true;
		}		
	}
	
	return $false;
}

filter Set-UserRightForSqlServer {
	param (
		[Parameter(Mandatory)]
		$InstanceName,
		[ValidateSet("PVMT", "LPIM")]
		[string]$UserRight
	);
	
	[string]$accountName = Get-SqlServerDefaultServiceAccount -InstanceName $InstanceName -AccountType "SqlServiceAccountName";
	
	$sid = ConvertTo-WindowsSecurityIdentifier -Name $accountName;
	$policy = Get-UserRightsPolicy;
	
	# template for use in creating new policies:
	$nlr = $policy | Select-String -Pattern "^SeNetworkLogonRight\s*=\s*.+";
	
	[bool]$modified = $false;
	if ($UserRight -eq "PVMT") {
		$pvmt = $policy | Select-String -Pattern "^SeManageVolumePrivilege\s*=\s*.+";
		
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
	elseif ($UserRight -eq "LPIM") {
		$lpim = $policy | Select-String -Pattern "^SeLockMemoryPrivilege\s*=\s*.+";
		
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
	else {
		throw "Proviso Framework Error. Invalid UserRight type specified for assignment.";
	}
	
	if ($modified) {
		[string]$secpolFile = "C:\Scripts\secpol.inf";
		
		$policy | Out-File $secpolFile -Force -Confirm:$false;
		SecEdit /configure /db secedit.sdb /cfg $secpolFile /areas USER_RIGHTS /overwrite /quiet | Out-Null;
		
		Remove-Item -Path $secpolFile;
	}
}

filter Remove-UserRightForSqlServer {
	param (
		[Parameter(Mandatory)]
		$InstanceName,
		[ValidateSet("PVMT", "LPIM")]
		[string]$UserRight
	);
	
	[string]$accountName = Get-SqlServerDefaultServiceAccount -InstanceName $InstanceName -AccountType "SqlServiceAccountName";
	
	# TODO: Implement... 
	# basically... just find and remove the assigned $sids ... then do the same thing... 
	throw "Proviso Framework Exception. User Rights REMOVALs are not CURRENTLY supported.";
}

filter Get-UserRightsPolicy {
	Mount-Directory "C:\Scripts";
	[string]$secpolFile = "C:\Scripts\secpol.inf";
	SecEdit /export /cfg $secpolFile /areas USER_RIGHTS /quiet | Out-Null;
	$policy = Get-Content -Path $secpolFile;
	
	Remove-Item -Path $secpolFile;
	
	return $policy;
}