Set-StrictMode -Version 1.0;

function Install-ADManagementToolsForPowerShell6Plus {
	# enables this 'module': https://docs.microsoft.com/en-us/powershell/module/addsadministration/?view=win10-ps
	# which includes such hits and fantastical beats as New-AdComputer (replacement for Add-Computer), and Get-ADServiceAccount, etc. 
	
	Install-WindowsFeature RSAT-AD-Powershell;
}