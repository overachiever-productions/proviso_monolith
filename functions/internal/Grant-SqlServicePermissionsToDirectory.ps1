Set-StrictMode -Version 1.0;

function Grant-SqlServicePermissionsToDirectory {
	
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$TargetDirectory,
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$SqlServiceAccount
	);
	
	$acl = Get-Acl $TargetDirectory;
	$rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule($SqlServiceAccount, "FullControl", "ContainerInherit,Objectinherit", "none", "Allow");
	
	$acl.SetAccessRule($rule);
	Set-Acl -Path $TargetDirectory -AclObject $acl;
}