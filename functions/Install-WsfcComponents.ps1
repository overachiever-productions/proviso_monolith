Set-StrictMode -Version 1.0;

function Install-WsfcComponents {
	
	# Fodder: https://docs.microsoft.com/en-us/powershell/module/failoverclusters/?view=windowsserver2019-ps
	
	$installed = (Get-WindowsFeature -Name Failover-Clustering).InstallState;
	switch ($installed) {
		"Installed" {
			Write-Host "WSFC Components already installed.";
		}
		"InstallPending" {
			Write-Host "WindowsFeature 'Failover-Clustering' is in InstallPending state - i.e., installed by machine requires restart.";
		}
		"Available" {
			Install-WindowsFeature Failover-Clustering -IncludeManagementTools | Out-Null;
		}
		default {
			throw "WindowsFeature 'Failover-Clustering' is in an unexpected state: $installed. Terminating Proviso Execution.";
		}
	}
	
	$powershellInstalled = (Get-WindowsFeature -Name RSAT-Clustering-PowerShell).InstallState;
	if ($powershellInstalled -ne "Installed") {
		Install-WindowsFeature RSAT-Clustering-PowerShell -IncludeAllSubFeature | Out-Null;
	}
}