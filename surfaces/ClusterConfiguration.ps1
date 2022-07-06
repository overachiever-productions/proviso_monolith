Set-StrictMode -Version 1.0;

<#
	
	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Map -ProvisoRoot "\\storage\Lab\proviso\";
	Target -ConfigFile "\\storage\lab\proviso\definitions\PRO\PRO-197.psd1" -Strict:$false;

	#$PVConfig.GetValue("ClusterConfiguration.MSSQLSERVER.Enabled");

	#Get-FacetTypeByKey -Key "ClusterConfiguration.MSSQLSERVER.ClusterNodes";

	
Get-ClusterWitnessTypeFromConfig

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
		# Yeah, needing domain creds - or not - totally depends upon the security setup of the environment/domain. 
		# 		I THINK the best option here might be: attempt to create WITHOUT domain creds
		# 			UNLESS: domain creds were supplied. 
		# 			and, when attempting to create without domain creds, look at options for trapping errors that would be indicative of 
		# 				problems with permissions and such - and try to surface those as much as possible. 
		#Assert-HasDomainCreds -ForClusterCreation -AssertOnConfigureOnly;
	}
	
	Aspect {
		Facet "ClusterType" -Key "ClusterType" -ExpectKeyValue {
			# Hmm. Happy-path coding below. Arguably, I should be checking for 2x things here: a) Get-Cluster (no name) to see if there's a cluster on this box that does NOT match the name being checked for, b) Get-Cluster $clusterName... to check for the expected cluster.
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.$instanceName.ClusterName");
				if ([string]::IsNullOrEmpty($clusterName)) {
					$PVContext.SetSurfaceState("$instanceName.ClusterExists", $false);
					return "NONE";
				}
				
				try {
					# TODO: this call takes 20-25 seconds if/when the cluster does NOT exist. 
					$cluster = Get-Cluster -Name $clusterName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
					if ($null -eq $cluster) {
						$PVContext.SetSurfaceState("$instanceName.ClusterExists", $false);
						$PVContext.SetSurfaceState("$instanceName.ACTUAL_ClusterType", "NONE");
						
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
					
					$PVContext.SetSurfaceState("$instanceName.ClusterExists", $true);
					$PVContext.SetSurfaceState("$instanceName.ACTUAL_ClusterType", $clusterType);
					return $clusterType;
				}
				catch {
					throw "Fatal Exception Evaluating Cluster Configuration: $_ `r`t$($_.ScriptStackTrace) ";
				}
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$clusterType = $PVContext.CurrentConfigKeyValue;
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.$instanceName.ClusterName");
				
				$clusterIps = @($PVConfig.GetValue("ClusterConfiguration.$instanceName.ClusterIPs"));
				
				$initialNodeClusterIp = $null;
				switch ($clusterIPs.Count) {
					{ $_ -eq 0 } {
						throw "Invalid Cluster Configuration - NO ClusterIPs have been specified for cluster [$clusterName]."; 
					}
					1 {
						$initialNodeClusterIp = $clusterIps[0];
					}
					default {
						# gt 1 at this point... 
						foreach ($definedIP in Get-ProvisoDefinedNetworkAddresses) {
							$parts = $definedIp -split '/';
							[IpAddress]$definedAddress = $parts[0];
							[IpAddress]$subnet = ConvertTo-SubnetMaskFromLength -CidrLength ([int]$parts[1]);
							
							foreach ($clusterIP in $clusterIPs) {
								if (Test-AreIpsInSameSubnet -FirstIp $definedAddress -SecondIp $clusterIP -SubnetMask $subnet) {
									$initialNodeClusterIp = $clusterIp;
									break;
								}
							}
						}
						
						if ($null -eq $initialNodeClusterIp) {
							throw "Invalid Cluster Configuration - A Cluster IP in the SAME SUBNET as the current host could NOT be found.";
						}
					}
				}
				
				if ("NONE" -eq $PVContext.GetSurfaceState("$instanceName.ACTUAL_ClusterType")) {
					$PVContext.WriteLog("Creating new cluster of type [$clusterType] as current cluster configuration is [NONE].", "Important");
					
					switch ($clusterType) {
						{ $_ -in @("AG", "SCALEOUT-AG") } {
							
							$PVContext.SetSurfaceState("$instanceName.SingleNodeClusterCreated", $true);
							New-SingleNodeAgCluster -ClusterName $clusterName -InitialNodeClusterIp $initialNodeClusterIp;
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
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.$instanceName.ClusterName");
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
				$instanceName = $PVContext.CurrentSqlInstance;
				
				if ("NONE" -ne $PVContext.GetSurfaceState("$instanceName.ACTUAL_ClusterType")) {
					$PVContext.WriteLog("Proviso will NOT change existing WSFC cluster names. Please make changes manually.", "Critical");
				}
			}
		}
		
		Facet "NodeMember" -Key "ClusterNodes" -ExpectIteratorValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.ClusterExists"))) {
					return "";
				}
				
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.$instanceName.ClusterName");
				if ([string]::IsNullOrEmpty($clusterName)) {
					return "";
				}
				
				$targetNode = $PVContext.CurrentConfigKeyValue;
				
				try {
					$node = Get-ClusterNode -Cluster $clusterName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Where-Object -Property Name -eq $targetNode;
					
					if ($node) {
						return ($node).Name;
					}
					
					return "";
				}
				catch {
					throw "Fatal Exception Extracting Cluster Nodes: $_ `r`t$($_.ScriptStackTrace) ";
				}
			}
			Configure {
				# If the cluster did NOT exist during evaluation, it has now been created. 
				# So, if the 'current' cluster node is both a) 'this' server and b) NOT part of the cluster, then add it. OTHERWISE, notify that we won't add other members.
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$targetNode = $PVContext.CurrentConfigKeyValue;
				$targetCluster = $PVConfig.GetValue("ClusterConfiguration.$instanceName.ClusterName");
				
				if ($targetNode -eq ([System.Net.Dns]::GetHostName())) {
					
					try {
						if ($PVContext.GetSurfaceState("$instanceName.SingleNodeClusterCreated")) {
							$PVContext.WriteLog("Skipping Addition of [$targetNode] to Cluster [$targetCluster] - as it was already added during SingleNode Setup.", "Debug");
						}
						else {
							$PVContext.WriteLog("Adding Node [$targetNode] to Cluster [$targetCluster].", "Important");
							Add-ClusterNode -Cluster $targetCluster -Name $targetNode | Out-Null;
						}
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
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.ClusterExists"))) {
					return "";
				}
				
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.$instanceName.ClusterName");
				if ([string]::IsNullOrEmpty($clusterName)) {
					return "";
				}
				
				$expectedIP = $PVContext.CurrentConfigKeyValue;
				
				$ips = Get-ClusterIpAddresses -ClusterName $clusterName;
				if ($ips -contains $expectedIP) {
					return $expectedIP;
				}
				
				return "";
			}
			Configure {
				# TODO: 
				# this needs to be redone/rethought. 
				# 	what's the goal here? 
				# 		i think the GOAL here is going to stem from a workflow like the following: 
				# 		1. we're on, say, SQL18 and create a cluster with ... SQL18 + a new clusterIP in play and add just a single node... SQL18. 
				# 		2. SQL19 - is on a different subnet, and now we're running this surface there... 
				# 			a. SQL19 needs to be added to the cluster... (handled in the nodes thingy... )
				# 			b. SQL19's subnet now, also, needs an IP for the cluster... 
				# 				in which case: 
				# 					there would be a 'missing' IP from the ACTUAL cluster (i.e., config would say we need 10.x.x.220, 10.x.y.220 and ONLY one of those would be loaded). 
				# 					the IP that's 'missing' from the cluster (e.g., 10.x.y.220) is in the same subnet as SQL19. 
				# 					in which case, we could then try to add the IP to the CLUSTER. 
				# 		
				# 		the logic above is NOT that hard/complex. 
				# 			what's missing with the implementation below (i think?) is that ... there's nothing going on to check/validate the REAL cluster vs JUST the config values. 
				
				# UPDATE: I think the above is true... ish. 
				# 	But I remember that the core function of the code below was, essentially: 
				# 		if an IP that's in the CONFIG is NOT in the cluster... 
				# 			then, verify if the CONFIG IP (which isn't in the cluster) is in the same SUBNET as an IP for the current box/server. 
				# 				IF those both match up, then ... yeah, we can add the additional/new/not-in-the-cluster-ip-(from-the-config)
				
				
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$expectedClusterIps = @($PVConfig.GetValue("ClusterConfiguration.$instanceName.ClusterIPs"));
				$currentClusterIpFromConfig = $PVContext.CurrentConfigKeyValue;
				
				# this logic doesn't make any sense... $currentClusterIP from CONFIG ... will always? be in $expectedClusterIpsFromConfig... 
				# 		i think what I need to do is check to see if the ... IP is in the cluster instead, right? 
				
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
					# NO... don't think so... all this would 'mean' is that the logic is busted and we've got an IP (from the config) that shouldn't be in the cluster - ... according to the config... confusing... 
					$PVContext.WriteLog("Removing Cluster IPs is not YET supported by Proviso.", "Critical");
				}
			}
		}
		
		Facet "WitnessType" -Key "Witness" {
			Expect {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.$instanceName.ClusterName");
				if ([string]::IsNullOrEmpty($clusterName)) {
					return "";
				}
				
				$witnessType = Get-ClusterWitnessTypeFromConfig -SqlInstanceName $instanceName;
				
				$PVContext.SetSurfaceState("$instanceName.EXPECTED_ClusterWitnessType", $witnessType);
				return $witnessType
			}
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.ClusterExists"))) {
					return "";
				}
				
				if ("NONE" -eq $PVContext.GetSurfaceState("$instanceName.ACTUAL_ClusterType")) {
					return "";
				}
				
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.$instanceName.ClusterName");
				$info = Get-ClusterWitnessInfo -ClusterName $clusterName;
				return $info.Type;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.$instanceName.ClusterName");
				
				$targetWitnessType = Get-ClusterWitnessTypeFromConfig -SqlInstanceName $instanceName;
				$actualWitnessType = (Get-ClusterWitnessInfo -ClusterName $clusterName).Type;
				
				if ("NONE" -eq $actualWitnessType) {
					$expectedPath = Get-FileShareWitnessPathFromConfig -SqlInstanceName $instanceName;
					Validate-ClusterWitnessFileSharePath -Path $expectedPath;
					
					$PVContext.WriteLog("Setting Cluster Quorum for Cluster [$clusterName] to FileShareWitness -> [$expectedPath].", "Important");
					Set-ClusterQuorum -FileShareWitness $expectedPath | Out-Null;
				}
				elseif (("FILESHARE" -eq $actualWitnessType) -and ("FILESHARE" -eq $targetWitnessType)) {
					# expected and actual are BOTH file-share - meaning that the PATH is not set and/or is incorrect. 
					$expectedPath = Get-FileShareWitnessPathFromConfig -SqlInstanceName $instanceName;
					Validate-ClusterWitnessFileSharePath -Path $expectedPath;
					
					$PVContext.WriteLog("Re-Setting/Updating Cluster Quorum for Cluster [$clusterName] to FileShareWitness -> [$expectedPath].", "Important");
					Set-ClusterQuorum -FileShareWitness $expectedPath | Out-Null;
				}
				else {
					# based on evictionbehavior (might need a better name)... warn, change, throw, whatever... 
					#  and/or just specify (when it makes sense - probably in MOST cases) ... that Proviso will NOT make changes to witness TYPES from x to y.
					
					throw "Cluster Witness type of [$targetWitnessType] is not yet supported.";
				}
			}
		}
		
		Facet "WitnessDetails" -Key "Witness" -Proctor "WitnessType" -ElideWhenProctorIs "NONE" {
			Expect {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.$instanceName.ClusterName");
				if ([string]::IsNullOrEmpty($clusterName)) {
					return "";
				}
				
				$witnessDetail = Get-ClusterWitnessDetailFromConfig -SqlInstanceName ($PVContext.CurrentSqlInstance);
				
				return $witnessDetail;
			}
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if (-not ($PVContext.GetSurfaceState("$instanceName.ClusterExists"))) {
					return "";
				}
				
				if ("NONE" -eq $PVContext.GetSurfaceState("$instanceName.ACTUAL_ClusterType")) {
					return "";
				}
				
				$clusterName = $PVConfig.GetValue("ClusterConfiguration.$instanceName.ClusterName");
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