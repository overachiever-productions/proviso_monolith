Set-StrictMode -Version 1.0;

function Grant-SqlServicePermissionsToDirectory {
	
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$TargetDirectory,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$SqlServiceAccountName
	);
	
	$acl = Get-Acl $TargetDirectory;
	
	$identity = $SqlServiceAccountName;
	$fileSystemRights = "FullControl";
	$type = "Allow";
	
	$args = $identity, $fileSystemRights, $type;
	$rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule($identity, $fileSystemRights, "ContainerInherit,Objectinherit", "none", $type);
	
	$acl.SetAccessRule($rule);
	Set-Acl -Path $TargetDirectory -AclObject $acl;
}