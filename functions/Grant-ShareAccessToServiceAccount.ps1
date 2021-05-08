Set-StrictMode -Version 1.0;

# REFACTOR: Maybe just: Grant-AccessToShare - cuz this current name sucks... 
function Grant-ShareAccessToServiceAccount {
	
	# Fodder - this stuff looks better than the SmbShare stuff: 
	#   https://docs.microsoft.com/en-us/powershell/module/storage/get-fileshare?view=win10-ps
	# 	https://docs.microsoft.com/en-us/powershell/module/storage/new-fileshare?view=win10-ps
	# 	https://docs.microsoft.com/en-us/powershell/module/storage/grant-fileshareaccess?view=win10-ps
	
	
	param (
		[string]$BackupDirectory,
		[string]$PartnerServiceAccountName,
		[string]$BackupShareName
	);
	
	Grant-SqlServerPermissionsToDirectories -TargetDirectory $BackupDirectory -SqlServiceAccountName $PartnerServiceAccountName;
	
	$exists = (Get-SmbShare "SQLBackups" -ErrorAction Ignore);
	
	if ($exists) {
		Write-Warning "SQLBackups has already been shared. Current logic NOT overwriting SMB Share definition...";
	}
	else {
		New-SmbShare -Name "SQLBackups" -Path $BackupDirectory -FullAccess $PartnerServiceAccountName, "AWS\ts-dba", "Administrators";
	}
}