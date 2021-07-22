Set-StrictMode -Version 1.0;
<#

	Used to load the 'path' for powershell when executed via restart / scheduled tasks and other needs. 

#>

function Get-VersionedPowershellExecutionPath {
	
	$path = $PSHOME;
	[int]$major = $PSVersionTable.PSVersion.Major;
	$exe = "powershell.exe";
	
	if ($major -gt 5) {
		$exe = "pwsh.exe"; 
	}
	
	return Join-Path $path -ChildPath $exe;
}