Set-StrictMode -Version 1.0;

function Install-ADManagementToolsForPowerShell6Plus {
	
	# I ERRONEOUSLY thought that 'this was the way' to get Add-Computer back into play on Powershell 6+. It's not.
	# BUT... there could be some really pertinent stuff here relative to CNO/VCO management and other AD-level stuff. 
	
	# Fodder: 
	# 		- https://docs.microsoft.com/en-us/powershell/module/addsadministration/?view=win10-ps
	# 		- https://docs.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2019-ps
	# 		- http://woshub.com/powershell-active-directory-module/
	
	Install-WindowsFeature RSAT-AD-Powershell;
}