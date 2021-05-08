Set-StrictMode -Version 1.0;

function Install-WsfcComponents {
	Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools | Out-Null;
	
	# Fodder: https://docs.microsoft.com/en-us/powershell/module/failoverclusters/?view=windowsserver2019-ps
	Add-WindowsFeature RSAT-Clustering-PowerShell | Out-Null;
}