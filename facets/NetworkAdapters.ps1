Set-StrictMode -Version 1.0;

Facet -For "Network-Adapters" {
	
	
<#	
	# define-each INSTEAD of Definitions. or, along-side it... i.e., can have Define-Each and Definitions be 'equal' to each other - use one or the other. 
	Define-Each -Key "Host.NetworkDefinitions" -OrderBy "ProvisioningPriority" {
		
		# note, these'll be refactored from 'Definition' to 'Define'... 
		
		Definition "InterfaceAliasSet" -Key "InterfaceAlias" {
			Test {
				# so ... this'd be for, say: "VMNetwork" or "HeartBeatNetwork" and so on... 
				#  and... the expectation is that ... for each of the 'adapters' above... 
				#   we'd be processing them IN ORDER (provisioning priority)
				#    and, this'd be a CHECK to see if, say, "VMNetwork" exists or NOT, or whether "HeartBeatNetwork" exists - or NOT. 
			}
			Configure {
				# then, down here, if it doesn't exist... then, look at assumableIfNames ... and try to assume/set. 
				# when we're done.... does the interface exist? yes or no (not: is it fully configured, just: does VMNetwork exist or does HeartBeatNetwork exist?)
			}
		}
		
		# might look to see if it makes sense to use the KEY as the name? (otherwise, i'd just need a define/definition name here)
		Definition -Key "IpAddress" {
			Test {
				# e.g., is the IP for "{VMNETWORK|HEARTBEATNETWORK|WHATEVER}" set to the IP specified? 
				#   or, more specifically what's the current IP of that adapter? (ProcessFacets will evaluate whether it's a match or not)
			}
			Configure {
				# set the IP to whatever it needs - for the interface in question. 
			}
		}
		
		Definition -Key "Gateway" {
			Test {
				# get the Gateway for Adapter XXX
			}
			Configure {
				# set the Gateway for Adapter XXX (i.e., if configure is getting called, it's to set the value to wahtever is in the config)
			}
		}
		
		Definition -Key "PrimaryDns" {
			# etc
		}
		
		Definition -Key "SecondaryDns" {
			# etc... 
		}
	}
#>
}



#		Definition -Has "VM-Network" {
#			Expect {
#				
#			}
#			Test {
#				Get-ExistingAdapters | Where-Object {$_.Name -eq $Config.GetValue("Host.NetworkDefinitions")}
#			}
#			Configure {
#				
#			}
#		}
#		
#		Definition -For "IP-Address" {
#			Expect {
#				$Config.GetValue("Host.NetworkDefinitions.VMNetwork.IpAddress");
#			}
#			Test {
#				
#			}
#			Configure {
#				
#			}
#		}