Set-StrictMode -Version 1.0;

function Install-SqlServerPowerShellModule {
	
	# vNEXT: 
	#   need to figure out if we have a network connection or not...  (i.e. outbound to the interwebs). 
	# 	if we don't, then the expectation is that we'll HAVE to deploy "SqlServer" from the ProvisoRepo instead of the default MS repo that ships with PowerShell 7+ etc. 
	
	if (!(Get-Module -Name SqlServer -ListAvailable)) {
		Install-Module SqlServer -Confirm:$false -Force | Out-Null;
	}
}