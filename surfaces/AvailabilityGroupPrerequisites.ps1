Set-StrictMode -Version 1.0;

# this entire surface COULD also, potentially, just be rolled into "AvailabilityGroupConfigurations" or AvailabilityGroupListener IF there ends up being ONLY the 1 facet (cno perms)
#  	that said... guessing there might be a few pre-requisites... 
Surface "AGPrerequisites" -Target "AvailabilityGroups" {
	Assertions {
		Assert-HasDomainCreds -ForClusterCreation -ConfigureOnly;
		
		#Assert-AGsDefinedInConfig;  # or something like this - i.e., NEED to tackle HOW to address scenarios where ... someone tries to run this and there are NO 
									 # details for AGs defined in the target config. i.e., WHAT do I do then/there? 
									# AND, arguably, for this particular surface... IF AGs aren't in the config... 
									# then, there will NOT be any facets. SO, that's something as well... 
	}
	
	Aspect {
		Facet "CNO Can Create Objects" -NoKey -Expect $true {
			Test {
				# needs to be scoped PER cluster/instance, right? 
				
				# https://docs.microsoft.com/en-us/archive/blogs/alwaysonpro/create-listener-fails-with-message-the-wsfc-cluster-could-not-bring-the-network-name-resource-online
			}
			Configure {
				
			}
		}
		
		Facet "SQLServerCanUseWsfcCluster" -NoKey -Expect $true {
			
			Test {
				
			}
			Configure {
				# Grant SQL Server the Ability to Leverage underlying WSFC: 
				# Only enable IF not already enabled:
#				$output = Invoke-SqlCmd -Query "SELECT SERVERPROPERTY('IsHadrEnabled') [result];";
#				
#				if ($output.result -ne 1) {
#					$machineName = $env:COMPUTERNAME;
#					
#					Enable-SqlAlwaysOn -Path SQLSERVER:\SQL\$machineName\DEFAULT -Force;
#					
#					#Once that's done, we'll almost certainly have to restart the SQL Server Agent cuz, again, SqlPS sucks... 
#					$agentStatus = (Get-Service SqlServerAgent).Status;
#					
#					if ($agentStatus -ne 'Running') {
#						Start-Service SqlServerAgent;
#					}
#				}
			}
		}
	}
}