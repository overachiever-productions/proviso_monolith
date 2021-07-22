Set-StrictMode -Version 1.0;

function Grant-SqlServicePermissionsToDirectory {
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Target,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$SqlServiceAccount
	);
	
	$acl = Get-Acl $Target;
	$rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule($SqlServiceAccount, "FullControl", "ContainerInherit,Objectinherit", "none", "Allow");
	
	$acl.SetAccessRule($rule);
	Set-Acl -Path $Target -AclObject $acl;
}