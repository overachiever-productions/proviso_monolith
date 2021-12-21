Set-StrictMode -Version 1.0;

Facet -For "NetworkAdapters" {
	
	Assertions {
		
	}
	
	Setup {
		
		$volumes = Get-ExistingVolumeLetters;
		$adapters = Get-ExistingNetAdapters;
		
		$PVContext.AddFacetState("CurrentVolumes", $volumes);
		$PVContext.AddFacetState("CurrentAdapters", $adapters);
	}
	
	Group-Definitions -GroupKey "Host.NetworkDefinitions.*" -OrderByChildKey "ProvisioningPriority" {
		Definition "IsInterfaceAlias.Exists" -Expect $true {
			Test {
				# Note: IfNames in the config are a bit weird... need to always look for EXPLICIT implmenations of Host.NetworkDefinitions.<AdapterName>.InterfaceAlias
				#  		that value will ALWAYS default to the name of the <AdapterName> IF it's not specified. BUT, if it IS specified it allows a shorthand <AdapterName> of
				# 			say HeartBeat to be translated to "Heartbeat Network" or whatever. 
				$currentAdapter = $PVContext.CurrentKeyGroup;
				$interfaceAlias = $PVConfig.GetValue("Host.NetworkDefinitions.$currentAdapter.InterfaceAlias");
				
				$currentAdapters = $PVContext.GetFacetState("CurrentAdapters");
				$matchedAdapter = $currentAdapters | Where-Object { $_.Name -eq $interfaceAlias };
				
				if ($matchedAdapter -and ($matchedAdapter.Status -eq "Up")) {
					return $true;
				}
				
				return $false;
			}
			Configure {
				$expectedIfName = $PVContext.CurrentKeyGroup;
				$assumableIfNames = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedIfName.AssumableIfNames");
				
				Write-Host "Can assume the following names: $assumableIfNames ";
			}
		}
	}
	
<#	
	# define-each INSTEAD of Definitions. or, along-side it... i.e., can have Define-Each and Definitions be 'equal' to each other - use one or the other. 
	Define-Each -Key "Host.NetworkDefinitions" -OrderBy "ProvisioningPriority" {
		
		# note, these'll be refactored from 'Definition' to 'Define'... 
				
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

