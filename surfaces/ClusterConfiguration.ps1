Set-StrictMode -Version 1.0;

<#
	
	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Map -ProvisoRoot "\\storage\Lab\proviso\";
	Target -ConfigFile "\\storage\lab\proviso\definitions\PRO\PRO-197.psd1" -Strict:$false;

	Validate-ClusterConfiguration;

#>


Surface ClusterConfiguration -Target "ClusterConfiguration" {
	Assertions {
		#Assert-WsfcComponentsInstalled;
		#Assert-IsDomainJoined -AssertOnConfigureOnly;   # not if/when the config-type is "WORKGROUP... "
		Assert-HasDomainCreds -ForClusterCreation -AssertOnConfigureOnly;
	}
	
	Aspect {
		Facet "ClusterType" -Key "ClusterType" -ExpectKeyValue {
			Test {
				try {
					$cluster = Get-Cluster -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
					if ($null -eq $cluster) {
						return "NONE";
					}
					else {
						$clusterType = "AG";
						$domain = (Get-CimInstance Win32_ComputerSystem).Domain;
						
						$disks = Get-ClusterResource | Where-Object -Property ResourceType -eq "Physical Disk";
						if ($null -ne $disks) {
							$clusterType = "FCI";
						}
						
						if ("WORKGROUP" -eq $domain) {
							$clusterType = "WORKGROUP-AG";
						}
						
						$nodes = Get-ClusterNode;
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
				if ("NONE" -eq $PVContext.GetSurfaceState("ACTUAL_ClusterType")) {
					$PVContext.WriteLog("Creating new cluster of type x as current cluster configuration is [NONE].", "Debug");
					
					
					Write-Host "Would be creating a new cluster at this point... ";
					
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
				try {
					$cluster = Get-Cluster -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
					
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
				try {
					$targetNode = $PVContext.CurrentConfigKeyValue;
					$node = Get-ClusterNode | Where-Object -Property Name -eq $targetNode;
					
					return $node;
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
					Write-Host "would now be adding $targetNode to cluster... $targetCluster "
				}
				else {
					# TODO: POSSIBLY re-evaluate this - the rub, of course, is that I have to know if, say, SQLA is already in the cluster, and we're running on/against SQLB and have added it (or will), and SQLC (i.e., not this box and not in cluster) is READY to be added to the cluster...
					$PVContext.WriteLog("Proviso can ONLY add [$targetNode] to Cluster [$targetCluster] if it 'knows' that the [$targetNode] has been fully validated and prepped - i.e., please run Proviso ON [$targetNode] to add it to the cluster.", "Critical");
				}
			}
		}
		
		Facet "ClusterIP" -Key "ClusterIPs" -ExpectIteratorValue {
			Test {
				$expectedIP = $PVContext.CurrentConfigKeyValue;
				
				$ips = Get-ClusterIpAddresses;
				if ($ips -contains $expectedIP) {
					return $expectedIP;
				}
				
				return "";
			}
			Configure {
				# hmmm. easy enough on cluster creation... 
				# but what if there's an additional IP? tend to think that I ONLY want to add that IF there's an ENTIRELY new node being added?
				# Oof. this one's kind of hard. 
				# 		in terms of adding cluster nodes (i.e., the facet before this one), i don't add them unless they're the 'current box'... 
				# 		and i think that makes sense here... 
				# only... IF I've got SQLA, SQLB, and SQLC ... and SQLA created the cluster, and we're now running on either SQLB or SQLC... adding either one of those (and alerting on not being able to add the OTHER) is easy. 
				# 		what'll be a challenge is ... how do I end up a) determining when to add an additional cluster IP? and b) convincing WSFC to do that/allow it? 
				# 		i.e., assume SQLA, SQLB are in different subnets, and SQLC is in the same as SQLA. 
				# 		if code is running on SQLC ... and I 'think' i should add the IP for SubnetB (i.e., SQLB), i don't think that WSFC will let me add a cluster IP for a subnet
				# 		other than the subnet I'm currently in? 
				# 		and so, maybe this isn't that hard... 
				# 			if the Cluster IP is similar to the current hosts's IP/subnet but is ... NOT in the cluster... then add it - the end? 
			}
		}
		
		Facet "WitnessType" -Key "Witness" {
			Expect {
				$witnessType = Get-ClusterWitnessTypeFromConfig;
								
				$PVContext.SetSurfaceState("EXPECTED_ClusterWitnessType", $witnessType);
				return $witnessType
			}
			Test {
				if ("NONE" -eq $PVContext.GetSurfaceState("ACTUAL_ClusterType")) {
					return "";
				}
				
				$info = Get-ClusterWitnessInfo;
				return $info.Type;
			}
			Configure {
				# If the witness hasn't been set up yet, create it as needed/expected. 
				# Otherwise, if it exists and is different... look at options for making CHANGES. 
			}
		}
		
		Facet "WitnessDetails" -Key "Witness" -Proctor "WitnessType" -ElideWhenProctorIs "NONE" {
			Expect {
				$witnessDetail = Get-ClusterWitnessDetailFromConfig;
				
				return $witnessDetail;
			}
			Test {
				if ("NONE" -eq $PVContext.GetSurfaceState("ACTUAL_ClusterType")) {
					return "";
				}
				
				$info = Get-ClusterWitnessInfo;
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
						return "<NOT_IMPLEMENTED>";  # not sure there's anything to return? (maybe the # of nodes? )
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