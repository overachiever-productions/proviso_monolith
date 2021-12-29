Set-StrictMode -Version 1.0;

function Install-WsfcComponents {
	
	# Fodder: https://docs.microsoft.com/en-us/powershell/module/failoverclusters/?view=windowsserver2019-ps
	$rebootRequired = $false;
	$processingError = $null;
	
	$installed = (Get-WindowsFeature -Name Failover-Clustering).InstallState;
	switch ($installed) {
		"Installed" {
			$PVContext.WriteLog("WSFC Components already installed.", "Debug");
		}
		"InstallPending" {
			$PVContext.WriteLog("Windows Feature 'Failover-Clustering' is in InstallPending state - i.e., installed by machine requires restart.", "Important");
			$rebootRequired = $true;
		}
		"Available" {
			try{
				Install-WindowsFeature Failover-Clustering -IncludeManagementTools -ErrorVariable processingError | Out-Null;
				
				if ($null -ne $processingError) {
					throw "Fatal error installing WSFC Components: $processingError ";
				}
			}
			catch {
				throw "Fatal Exception Encountered during installation of WSFC Components: $_ `r`t$($_.ScriptStackTrace)";
			}
			
			if ($null -eq $processingError) {
				$rebootRequired = $true;
			}
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