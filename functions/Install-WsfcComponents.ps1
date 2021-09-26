Set-StrictMode -Version 1.0;

function Install-WsfcComponents {
	
	# Fodder: https://docs.microsoft.com/en-us/powershell/module/failoverclusters/?view=windowsserver2019-ps
	
	$rebootRequired = $false;
	$processingError = $null;
	
	$installed = (Get-WindowsFeature -Name Failover-Clustering).InstallState;
	switch ($installed) {
		"Installed" {
			Write-ProvisoLog -Message "WSFC Components already installed." -Level Important;
		}
		"InstallPending" {
			Write-ProvisoLog -Message "WindowsFeature 'Failover-Clustering' is in InstallPending state - i.e., installed by machine requires restart." -Level Important;
			$rebootRequired = $true;
		}
		"Available" {
			# TODO: this can't be Out-Null only/solely. need some sort of error handling. 
			#   otherwise, IF there's a problem installing WSFC stuff... the error is silent, $rebootaRequired = $true, and we end up in a vicious reboot cycle... 
			Install-WindowsFeature Failover-Clustering -IncludeManagementTools -ErrorVariable processingError | Out-Null;
			$rebootRequired = $true;
		}
		default {
			throw "WindowsFeature 'Failover-Clustering' is in an unexpected state: $installed. Terminating Proviso Execution.";
		}
	}
	
	$powershellInstalled = (Get-WindowsFeature -Name RSAT-Clustering-PowerShell).InstallState;
	if ($powershellInstalled -ne "Installed") {
		Install-WindowsFeature RSAT-Clustering-PowerShell -IncludeAllSubFeature | Out-Null;
		$rebootRequired = $true;
	}
	
	return $rebootRequired;
}