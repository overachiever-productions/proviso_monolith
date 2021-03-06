Set-StrictMode -Version 1.0;

function Install-WsfcComponents {
	Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools;
}