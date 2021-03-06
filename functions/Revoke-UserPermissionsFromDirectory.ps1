Set-StrictMode -Version 1.0;

function Revoke-UserPermissionsFromDirectory {
	
	param (
		[string]$TargetDirectory,
		[string]$UserToRemove
	);
	
	# fodder/source: https://stackoverflow.com/questions/13513863/powershell-remove-all-permissions-on-a-folder-for-a-specific-user
	
	# TODO: validate that the sid is valid before processing... 
	#$sid = ConvertTo-WindowsSecurityIdentifier -DomainUser $UserToRemove;
	
	# TODO: validate that the directory exists... 
	
	$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($TargetDirectory, "Read",,, "Allow");
	$acl = Get-Acl $TargetDirectory;
	
	$acl.RemoveAccessRuleAll($rule);
	
	Set-Acl -Path $TargetDirectory -AclObject $acl
}