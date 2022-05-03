Set-StrictMode -Version 1.0;

Surface ClusterConfiguration -Target "ClusterConfiguration" {
	Assertions {
		#Assert-WsfcComponentsInstalled;
		#Assert-IsDomainJoined;   # not if/when the config-type is "WORKGROUP... "
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
					
					return $clusterType;
				}
				catch {
					throw "Fatal Exception Evaluating Cluster Configuration: $_ `r`t$($_.ScriptStackTrace) ";
				}
			}
			Configure {
				# if a cluster should exist, but doesn't... then create it. 
				# 		initially, simple AG clusters are ALL that will be supported. 
				# 
				# if a cluster should NOT exist or is of a different type
				# 		or if the names do NOT match up... 
				# then use the ClusterConfiguration.EvictionBehavior ... to throw warnings/alerts and whatever... 
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
				# oof... if it doesn't exist, that's fine... we'll create it. 
				# but certainly NOT changing the name... ever. 
				# 		i.e., see that info about (in ClusterType facet) about ClusterConfiguration.EvictionBehavior and warnings/alerts/etc. 
			}
		}
		
		Facet "ClusterNodes" -Key "ClusterNodes" -ExpectIteratorValue {
			Test {
				try {
					$targetNode = $PVContext.CurrentKeyValue;
					$node = Get-ClusterNode | Where-Object -Property Name -eq $targetNode;
					
					# vNEXT: Possibly look at providing info about State (i.e., Up or Down.). 
					#  	That said... Proviso is a CONFIGURATION tool - not an HA / monitoring tool - so ... if the node exists, i THINK we're done...
					return $node;
				}
				catch {
					throw "Fatal Exception Extracting Cluster Nodes: $_ `r`t$($_.ScriptStackTrace) ";
				}
			}
			Configure {
				# if no cluster exists, create with target nodes. 
				# if a node is MISSING... then... add it. (scary)
			}
		}
		
#		Facet "ClusterIPs" -Key "ClusterIPs" -ExpectIteratorValue {
#			Test {
#				# Sigh. This one will HAVE to be done via 'native' PowerShell - i.e., whatever ships ON the box in question... 
#				#   which... is a pain... (cuz it means Posh 5 for 2019, Posh ? for 2022, Posh ? for 2016, etc. )
#				#  		i THINK that the 'native' shell on ALL windows boxes is probably in/at the same location on disk? but if not, that complicates things further.
#				#    https://serverfault.com/questions/1081934/windows-failover-clutser-cant-set-cluster-resource
#			}
#			Configure {
#				# hmmm. easy enough on cluster creation... 
#				# but what if there's an additional IP? tend to think that I ONLY want to add that IF there's an ENTIRELY new node being added?
#			}
#		}
		
		# vNEXT: This is currently hard-coded:
#		Facet "Witness Type" -Key "Witness" -Expect "FileShare" {
#			Test {
#				
#			}
#			Configure {
#				# hmmmm... do we defer to 
#			}
#		}
		
		Facet "Witness" -Key "Witness" {
			Expect {
				# vNEXT: support options OTHER than FileShare witnesses. 
				$values = $PVConfig.GetValue("ClusterConfiguration.Witness");
				$fileShareWitness = $values.FileShareWitness;
				
				return $fileShareWitness; 
			}
			Test {
				
			}
			Configure {
				# this one CAN be changed... but, if it gets changed, then should spit out an IMPORTANT warning/etc. 
				
			}
		}
	}
}