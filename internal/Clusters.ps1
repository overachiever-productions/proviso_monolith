Set-StrictMode -Version 1.0;

filter Get-SelfRemotingToNativePoshEnabled {
	try {
		if (-not ([bool](Test-WSMan -ComputerName . -ErrorAction SilentlyContinue))) {
			return $false;
		}
		
		$version = Invoke-Command -ComputerName . {
			$PSVersionTable.PSVersion.Major;
		} -ErrorAction SilentlyContinue;
		
		if (5 -ne $version) {
			return $false;
		}
	}
	catch {
		return $false;
	}
	
	return $true;
}

filter Enable-SelfRemotingToNativePosh {
	
	try {
		$posh5Path = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe";
		$arguments = "Enable-PSRemoting -Force;"; # NOTE: do NOT -SkipNetworkProfileCheck - that's for 'PUBLIC' NICs: https://www.dtonias.com/enable-powershell-remoting-check-enabled/
		
		& "$posh5Path" $arguments | Out-Null;
	}
	catch {
		throw "Fatal Exception Enabling PSRemoting for access to Native PowerShell: $_ `r`t$($_.ScriptStackTrace)";
	}
}

filter Disable-SelfRemotingToNativePosh {
	try {
		$posh5Path = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe";
		$arguments = "Disable-PSRemoting -Force;";
		
		& "$posh5Path" $arguments | Out-Null;
	}
	catch {
		throw "Fatal Exception Disabling PSRemoting for access to Native PowerShell: $_ `r`t$($_.ScriptStackTrace)";
	}
}

filter Get-ClusterIpAddresses {
	param (
		[string]$ClusterName	
	);
	
	[ScriptBlock]$code = {
		param ([string]$ClusterName);
		Get-ClusterResource  -Cluster $ClusterName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Where-Object {
			($_.ResourceType -eq "IP Address") -and ($_.OwnerGroup -eq "Cluster Group")
		} | Get-ClusterParameter -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Where-Object {
			$_.Name -eq "Address"
		} | Select-Object -Property Value;
	};
	
	$output = @((Invoke-Command -ComputerName . $code -ArgumentList $ClusterName)).Value;
	
	return $output;
}

filter Get-ClusterWitnessInfo {
	param (
		[Parameter(Mandatory)]
		[string]$ClusterName
	);
	
	$clusterInfo = @{
	};
	try {
		$quorum = Get-ClusterQuorum -Cluster $clusterName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
		switch (($quorum).QuorumResource) {
			{ $null -or [string]::IsNullOrEmpty($_) } {
				$clusterInfo.Add("Type", "NONE");
			}
			{ $_ -like "File Share Witnes*" } {
				$clusterInfo.Add("Type", "FILESHARE");
				
				
				[ScriptBlock]$code = {
					param ([string]$ClusterName);
					(Get-ClusterResource -Cluster $clusterName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Where-Object {
							$_.ResourceType -eq "File Share Witness"
						} | Get-ClusterParameter -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Where-Object {
							$_.Name -eq "SharePath"
						}).Value;
				};
				
				$output = Invoke-Command -ComputerName . $code -ArgumentList $ClusterName;
				
				$clusterInfo.Add("SharePath", $output);
			}
			{ $_ -like "Cluster Disk*" } {
				$clusterInfo.Add("Type", "DISK");
			}
			# TODO: add an entry for CLOUD
			# TODO: add an entry for QUORUM (majority)
			default {
				return "<UNSUPPORTED>"; # for now just return this... 
			}
		}
	}
	catch {
		throw "Fatal Exception evaluating Cluster Witness/Quorum information: $_ `r`t$($_.ScriptStackTrace)";
	}
	
	return $clusterInfo;
}

filter Validate-ClusterWitnessFileSharePath {
	param (
		[Parameter(Mandatory)]
		[string]$SharePath
	);
	
	# TODO: implement this. there should be 2x checks: 
	# 	1. verify that the path exists... 
	# 	2. verify that the CNO/current-host? has permissions to the share/directory in question. 
	# 		note that if EVERYONE has perms to the folder/share ... then we're covered.
	
	# throw if either of the above is NOT true/expected.
}

#region Copy/Pasted from OLD (i.e., not yet implemented/updated)
filter Grant-CnoPermissionsToCreateObjects {
	## i.e., (automate) this
	# https://docs.microsoft.com/en-us/archive/blogs/alwaysonpro/create-listener-fails-with-message-the-wsfc-cluster-could-not-bring-the-network-name-resource-online
	
	
	# NOTE:(from the _OLD func: Install-ADManagementToolsForPowerShell6Plus )
	# I ERRONEOUSLY thought that 'this was the way' to get Add-Computer back into play on Powershell 6+. It's not.
	# BUT... there could be some really pertinent stuff here relative to CNO/VCO management and other AD-level stuff. 
	
	# Fodder: 
	# 		- https://docs.microsoft.com/en-us/powershell/module/addsadministration/?view=win10-ps
	# 		- https://docs.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2019-ps
	# 		- http://woshub.com/powershell-active-directory-module/
	
	Install-WindowsFeature RSAT-AD-Powershell;
	
	
}

filter Grant-SqlServerAccessToWsfcCluster {
	# Grant SQL Server the Ability to Leverage underlying WSFC: 
#	# Only enable IF not already enabled:
#	$output = Invoke-SqlCmd -Query "SELECT SERVERPROPERTY('IsHadrEnabled') [result];";
#	
#	if ($output.result -ne 1) {
#		$machineName = $env:COMPUTERNAME;
#		
#		Enable-SqlAlwaysOn -Path SQLSERVER:\SQL\$machineName\DEFAULT -Force;
#		
#		#Once that's done, we'll almost certainly have to restart the SQL Server Agent cuz, again, SqlPS sucks... 
#		$agentStatus = (Get-Service SqlServerAgent).Status;
#		
#		if ($agentStatus -ne 'Running') {
#			Start-Service SqlServerAgent;
#		}
#	}
}

filter Revoke-SqlServerAccessToWsfcCluster {
	
#	# Only disable IF enabled:
#	$output = Invoke-SqlCmd -Query "SELECT SERVERPROPERTY('IsHadrEnabled') [result];";
#	
#	if ($output.result -eq 1) {
#		$machineName = $env:COMPUTERNAME;
#		
#		Disable-SqlAlwaysOn -Path SQLSERVER:\SQL\$machineName\DEFAULT -Force;
#		
#		#Once that's done, we'll almost certainly have to restart the SQL Server Agent cuz, again, SqlPS sucks... 
#		$agentStatus = (Get-Service SqlServerAgent).Status;
#		
#		if ($agentStatus -ne 'Running') {
#			Start-Service SqlServerAgent;
#		}
#	}
}

#endregion