Set-StrictMode -Version 1.0;

<#
	
	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Map -ProvisoRoot "\\storage\Lab\proviso\";
	Target -ConfigFile "\\storage\lab\proviso\definitions\PRO\PRO-197.psd1" -Strict:$false;

	$PVConfig.GetValue("AvailabilityGroups.MSSQLSERVER.Enabled");


	Validate-ClusterConfiguration;

#>

Surface ClusterConfiguration -Target "ClusterConfiguration" {
	Assertions {
		Assert "WSFC Components Installed" {
			$installed = (Get-WindowsFeature -Name Failover-Clustering).InstallState;
			if ($installed -ne "Installed") {
				return $false;
			}
		}
		
		Assert "PowerShell v5 Self-Remoting Enabled" {
			if (-not (Get-SelfRemotingToNativePoshEnabled)) {
				return $false;
			}
		}
		
		# TODO: Look at options to address this... 
		#		Assert "Cluster Object Name Does NOT Already Exist" {
		#			# er... well, kind of like checking for whether or not a ServerName ALREADY exists in AD - even though it hasn't yet been 'created'
		#			# 			i.e., if it's a 'turd' from before... then... need to throw/remove... 
		#			# 			the rub, of course, is that ...  I need to figure out if the cluster EXISTS (on the current box)
		#			# 				and, if not, if the CNO exists in AD... 
		#		}
		
		#		Assert "Is Domain Joined" {
		#			# well... not if/when the TYPE of cluster is a workgroup cluster... 
		# 			# in those cases, probably need to verify that DNS suffixes are in play... 
		#		}
		
		# TODO: re-asses ... so far... i don't actually NEED these in LAB... 
		Assert-HasDomainCreds -ForClusterCreation -AssertOnConfigureOnly;
	}
	
	Aspect {
		Facet "ClusterType" -Key "ClusterType" -ExpectKeyValue {
			# Hmm. Happy-path coding below. Arguably, I should be checking for 2x things here: a) Get-Cluster (no name) to see if there's a cluster on this box that does NOT match the name being checked for, b) Get-Cluster $clusterName... to check for the expected cluster.
			Test {
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.ClusterName");
				if ([string]::IsNullOrEmpty($clusterName)) {
					return "NONE";
				}
				
				try {
					$cluster = Get-Cluster -Name $clusterName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
					if ($null -eq $cluster) {
						return "NONE";
					}
					else {
						$clusterType = "AG";
						$domain = (Get-CimInstance Win32_ComputerSystem).Domain;
						
						$disks = Get-ClusterResource -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Where-Object -Property ResourceType -eq "Physical Disk";
						if ($null -ne $disks) {
							$clusterType = "FCI";
						}
						
						if ("WORKGROUP" -eq $domain) {
							$clusterType = "WORKGROUP-AG";
						}
						
						$nodes = Get-ClusterNode -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
						if ($nodes.Count -gt 2) {
							if ("AG" -eq $clusterType) {
								$clusterType = "SCALEOUT-AG";
							}
							else {
								$clusterTyupe = "MULTINODE-FCI";
							}
						}
					}
					
					$PVContext.SetSurfaceState("ACTUAL_ClusterType", $clusterType);
					return $clusterType;
				}
				catch {
					throw "Fatal Exception Evaluating Cluster Configuration: $_ `r`t$($_.ScriptStackTrace) ";
				}
			}
			Configure {
				$clusterType = $PVContext.CurrentConfigKeyValue;
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.ClusterName");
				$intialNode = $PVContext.GetSurfaceState("CurrentExpectedClusterNode");
				$initialNodeClusterIp = $PVContext.GetSurfaceState("CurrentExpectedClusterIp");
				
				if ("NONE" -eq $PVContext.GetSurfaceState("ACTUAL_ClusterType")) {
					$PVContext.WriteLog("Creating new cluster of type [$clusterType] as current cluster configuration is [NONE].", "Important");
					
					switch ($clusterType) {
						{ $_ -in @("AG", "SCALEOUT-AG") } {
							
							New-SingleNodeAgCluster -ClusterName $clusterName -InitialNode $intialNode -InitialNodeClusterIp $initialNodeClusterIp;
						}
						"WORGROUP" {
							throw "WORKGROUP Clusters are not YET supported in Proviso.";
						}
						{ $_ -in @("FCI", "MULTINODE-FCI") } {
							throw "FCIs are not YET supported in Proviso";
						}
						default {
							throw "Invalid Cluster Type defined: [$clusterTYpe].";
						}
					}
				}
				else {
					throw "Not Implemented. Changing Cluster Types and/or Tearing down Clusters is not YET supported.";
					
					# don't think I'll ever support much more than switching from AG to AGx in here... 
					# and supporting tear-down if/when the "EvictionBehavior" is set to "FORCE";
					
				}
			}
		}
		
		Facet "ClusterName" -Key "ClusterName" -ExpectKeyValue -Proctor "ClusterType" -ElideWhenProctorIs "NONE" {
			Test {
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.ClusterName");
				if ([string]::IsNullOrEmpty($clusterName)) {
					return "";
				}
				
				try {
					$clusterName = $PVContext.CurrentConfigKeyValue;
					$cluster = Get-Cluster -Name $clusterName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
					
					return ($cluster).Name;
				}
				catch {
					throw "Fatal Exception Extracting Cluster Name: $_ `r`t$($_.ScriptStackTrace) ";
				}
			}
			Configure {
				$PVContext.WriteLog("Proviso will NOT change existing WSFC cluster names. Please make changes manually.", "Critical");
			}
		}
		
		Facet "NodeMember" -Key "ClusterNodes" -ExpectIteratorValue {
			Test {
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.ClusterName");
				if ([string]::IsNullOrEmpty($clusterName)) {
					return "";
				}
				
				try {
					$targetNode = $PVContext.CurrentConfigKeyValue;
					$node = Get-ClusterNode -Cluster $clusterName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Where-Object -Property Name -eq $targetNode;
					
					if ($node) {
						$PVContext.SetSurfaceState("CurrentExpectedClusterNode", ($node).Name);
						return ($node).Name;
					}
				}
				catch {
					throw "Fatal Exception Extracting Cluster Nodes: $_ `r`t$($_.ScriptStackTrace) ";
				}
			}
			Configure {
				# If the cluster did NOT exist during evaluation, it has now been created. 
				# So, if the 'current' cluster node is both a) 'this' server and b) NOT part of the cluster, then add it. OTHERWISE, notify that we won't add other members.
				
				$targetNode = $PVContext.CurrentConfigKeyValue;
				$targetCluster = $PVConfig.GetValue("ClusterConfiguration.ClusterName");
				
				if ($targetNode -eq ([System.Net.Dns]::GetHostName())) {
					
					try {
						$PVContext.WriteLog("Adding Node [$targetNode] to Cluster [$targetCluster].", "Important");
						Add-ClusterNode -Cluster $targetCluster -Name $targetNode | Out-Null;
					}
					catch {
						throw "Fatal Exception adding [$targetNode] to [$targetCluster]: $_ `r`t$($_.ScriptStackTrace) ";
					}
				}
				else {
					# TODO: POSSIBLY re-evaluate this - the rub, of course, is that I have to know if, say, SQLA is already in the cluster, and we're running on/against SQLB and have added it (or will), and SQLC (i.e., not this box and not in cluster) is READY to be added to the cluster...
					$PVContext.WriteLog("Proviso will ONLY add [$targetNode] to Cluster [$targetCluster] when executed on/from [$targetNode].", "Important");
				}
			}
		}
		
		Facet "ClusterIP" -Key "ClusterIPs" -ExpectIteratorValue {
			Test {
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.ClusterName");
				if ([string]::IsNullOrEmpty($clusterName)) {
					return "";
				}
				
				$expectedIP = $PVContext.CurrentConfigKeyValue;
				
				$ips = Get-ClusterIpAddresses -ClusterName $clusterName;
				if ($ips -contains $expectedIP) {
					$PVContext.SetSurfaceState("CurrentExpectedClusterIp", $expectedIP);
					return $expectedIP;
				}
				
				return "";
			}
			Configure {
				$expectedClusterIps = $PVConfig.GetValue("ClusterConfiguration.ClusterIPs");
				$currentClusterIpFromConfig = $PVContext.CurrentConfigKeyValue;
				
				if ($currentClusterIpFromConfig -notin $expectedClusterIps) {
					# get a list of all config-defined IPs on this box, and if one of those is in the same subnet as this IP ... go ahead and add it. 
					$definedAdapters = $PVConfig.GetObjects("Host.NetworkDefinitions");
					foreach ($definedAdapter in $definedAdapters) {
						[string]$definedIp = $PVConfig.GetValue("Host.NetworkDefinitions.$definedAdapter.IpAddress");
						
						$parts = $definedIp -split '/';
						[IpAddress]$address = $parts[0];
						[IpAddress]$subnet = ConvertTo-SubnetMaskFromLength -CidrLength ([int]$parts[1]);
						
						if (Test-AreIpsInSameSubnet -FirstIp $address -SecondIp $currentClusterIpFromConfig -SubnetMask $subnet) {
							$PVContext.WriteLog("Adding Expected ClusterIp [$currentClusterIpFromConfig] to Cluster because it is in the same subnet as [$address] - on adapter [$definedAdapter].", "Important");
							
							# TODO: add the cluster IP ... 
							
						}
					}
				}
				else {
					# we're dealing with a remove operation?  
					$PVContext.WriteLog("Removing Cluster IPs is not YET supported by Proviso.", "Critical");
				}
			}
		}
		
		Facet "WitnessType" -Key "Witness" {
			Expect {
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.ClusterName");
				if ([string]::IsNullOrEmpty($clusterName)) {
					return "";
				}
				
				$witnessType = Get-ClusterWitnessTypeFromConfig;
				
				$PVContext.SetSurfaceState("EXPECTED_ClusterWitnessType", $witnessType);
				return $witnessType
			}
			Test {
				if ("NONE" -eq $PVContext.GetSurfaceState("ACTUAL_ClusterType")) {
					return "";
				}
				
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.ClusterName");
				$info = Get-ClusterWitnessInfo -ClusterName $clusterName;
				return $info.Type;
			}
			Configure {
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.ClusterName");
				
				$targetWitnessType = Get-ClusterWitnessTypeFromConfig;
				$actualWitnessType = (Get-ClusterWitnessInfo -ClusterName $clusterName).Type;
				
				if ("NONE" -eq $actualWitnessType) {
					$expectedPath = Get-FileShareWitnessPathFromConfig;
					Validate-ClusterWitnessFileSharePath -Path $expectedPath;
					
					$PVContext.WriteLog("Setting Cluster Quorum for Cluster [$clusterName] to FileShareWitness -> [$expectedPath].", "Important");
					Set-ClusterQuorum -FileShareWitness $expectedPath | Out-Null;
				}
				elseif (("FILESHARE" -eq $actualWitnessType) -and ("FILESHARE" -eq $targetWitnessType)) {
					# expected and actual are BOTH file-share - meaning that the PATH is not set and/or is incorrect. 
					$expectedPath = Get-FileShareWitnessPathFromConfig;
					Validate-ClusterWitnessFileSharePath -Path $expectedPath;
					
					$PVContext.WriteLog("Re-Setting/Updating Cluster Quorum for Cluster [$clusterName] to FileShareWitness -> [$expectedPath].", "Important");
					Set-ClusterQuorum -FileShareWitness $expectedPath | Out-Null;
				}
				else {
					# based on evictionbehavior (might need a better name)... warn, change, throw, whatever... 
					#  and/or just specify (when it makes sense - probably in MOST cases) ... that Proviso will NOT make changes to witness TYPES from x to y.
				}
			}
		}
		
		Facet "WitnessDetails" -Key "Witness" -Proctor "WitnessType" -ElideWhenProctorIs "NONE" {
			Expect {
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.ClusterName");
				if ([string]::IsNullOrEmpty($clusterName)) {
					return "";
				}
				
				$witnessDetail = Get-ClusterWitnessDetailFromConfig;
				
				return $witnessDetail;
			}
			Test {
				if ("NONE" -eq $PVContext.GetSurfaceState("ACTUAL_ClusterType")) {
					return "";
				}
				
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.ClusterName");
				$info = Get-ClusterWitnessInfo -ClusterName $clusterName;
				switch ($info.Type) {
					"NONE" {
						return "";
					}
					"FILESHARE" {
						return $info.SharePath;
					}
					"DISK" {
						return "<NOT_IMPLEMENTED>";
					}
					"CLOUD" {
						return "<NOT_IMPLEMENTED>";
					}
					"QOURUM" {
						return "<NOT_IMPLEMENTED>"; # not sure there's anything to return? (maybe the # of nodes? )
					}
					default {
						return "<UNKNONWN>";
					}
				}
			}
			Configure {
				$PVContext.WriteLog("Witness configuration details are handled in the WitnessType Facet.", "Debug");
			}
		}
	}
}