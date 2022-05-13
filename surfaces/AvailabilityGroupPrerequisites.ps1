#Set-StrictMode -Version 1.0;
#
## this entire surface COULD also, potentially, just be rolled into "AvailabilityGroupConfigurations" or AvailabilityGroupListener IF there ends up being ONLY the 1 facet (cno perms)
##  	that said... guessing there might be a few pre-requisites... 
#Surface "ClusterPrerequisites" -Target "AvailabilityGroups" {
#	Assertions {
#		
#	}
#	
#	Aspect {
#		Facet "CNOCreateObjectsEnabled" {
#			Test {
#				# https://docs.microsoft.com/en-us/archive/blogs/alwaysonpro/create-listener-fails-with-message-the-wsfc-cluster-could-not-bring-the-network-name-resource-online
#			}
#			Configure {
#				
#			}
#		}
#		
#		# this facet COULD be thrown somewhere else... if/as needed (i.e., might even make sense as part of 'core' AG stuff.)
##		Facet "SQLServerCanUseWsfcCluster" {
##			# Grant SQL Server the Ability to Leverage underlying WSFC: 
##			# Only enable IF not already enabled:
##			$output = Invoke-SqlCmd -Query "SELECT SERVERPROPERTY('IsHadrEnabled') [result];";
##			
##			if ($output.result -ne 1) {
##				$machineName = $env:COMPUTERNAME;
##				
##				Enable-SqlAlwaysOn -Path SQLSERVER:\SQL\$machineName\DEFAULT -Force;
##				
##				#Once that's done, we'll almost certainly have to restart the SQL Server Agent cuz, again, SqlPS sucks... 
##				$agentStatus = (Get-Service SqlServerAgent).Status;
##				
##				if ($agentStatus -ne 'Running') {
##					Start-Service SqlServerAgent;
##				}
##			}
##		}
#	}
#}