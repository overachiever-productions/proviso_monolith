Set-StrictMode -Version 1.0;

function Install-WindowsManagementCommands {
	
	# Obviously, this only works on Windows machines ... and we're using it to get Add-Computer back 'in the mix'. 
	
	# Fodder: 
	# 		- https://docs.microsoft.com/en-us/answers/questions/382685/powershell-7-unjoin-computer-from-domain.html
	# 		- https://docs.microsoft.com/en-us/powershell/module/Microsoft.PowerShell.Core/About/about_windows_powershell_compatibility?view=powershell-7.1
	
	Import-Module Microsoft.PowerShell.Management -UseWindowsPowerShell;
	
}