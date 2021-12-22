Set-StrictMode -Version 1.0;

Facet -For "NetworkAdapters" {
	
	Setup {
		$adapters = Get-ExistingNetAdapters;
		$ipConfigs = Get-ExistingIpConfigurations;
		
		$PVContext.AddFacetState("CurrentAdapters", $adapters);
		$PVContext.AddFacetState("CurrentIpConfigurations", $ipConfigs);
	}
	
	Assertions {
		
	}
	
	Group-Definitions -GroupKey "Host.NetworkDefinitions.*" -OrderByChildKey "ProvisioningPriority" {
		Definition "Interface.Exists" -Expect $true {
			Test {
				# Note: IfNames in the config are a bit weird... need to always look for EXPLICIT implmenations of Host.NetworkDefinitions.<AdapterName>.InterfaceAlias
				#  		that value will ALWAYS default to the name of the <AdapterName> IF it's not specified. BUT, if it IS specified it allows a shorthand <AdapterName> of
				# 			say HeartBeat to be translated to "Heartbeat Network" or whatever. 
				$currentAdapter = $PVContext.CurrentKeyGroup;
				$interfaceAlias = $PVConfig.GetValue("Host.NetworkDefinitions.$currentAdapter.InterfaceAlias");
				
				$currentAdapters = $PVContext.GetFacetState("CurrentAdapters");
				$matchedAdapter = $currentAdapters | Where-Object { $_.Name -eq $interfaceAlias };
				
				if ($matchedAdapter -and ($matchedAdapter.Status -eq "Up")) {
					$PVContext.AddFacetState("$($currentAdapter).matchedAdapter", $matchedAdapter);
					return $true;
				}
				
				return $false;
			}
			Configure {
				$expectedIfName = $PVContext.CurrentKeyGroup;
				
				$interfaceAlias = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedIfName.InterfaceAlias");
				$assumableAdapters = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedIfName.AssumableIfNames");
				
	#Write-Host "Can assume the following names: $assumableAdapters for target interface $expectedIfName ";
				
				$currentAdapters = $PVContext.GetFacetState("CurrentAdapters");
				
				$matchedAdapter = $null;
				foreach ($assumableTarget in $assumableAdapters) {
					$matchedAdapter = $CurrentAdapters | Where-Object {
						($_.Name -eq $assumableTarget) -and ($_.Status -eq "Up")
					};
					
					if ($matchedAdapter -ne $null) {
						break;
					}
				}
				
				if ($matchedAdapter -eq $null) {
					throw "Expected Adapter [$expectedIfName] was NOT FOUND and no matching AssumableIfNames were matched. Network provisioning is terminating.";
				}
				
	#Write-Host "Found an assumable Interface... $($matchedAdapter.Name)"
				
				try {
					$matchedAdapterName = $matchedAdapter.Name;
					
					$PVContext.WriteLog("Renaming '$matchedAdapterName' to '$interfaceAlias'. ", "Important");
					#Rename-NetAdapter -Name $matchedAdapterName -NewName $interfaceAlias;
					
					$actualAdapter = $CurrentAdapters | Where-Object {
						$_.Name -eq $matchedAdapterName
					};
					
					$PVContext.AddFacetState("$expectedIfName.ACTUAL_ADAPTER", $actualAdapter);
				}
				catch {
					throw "Unexpected error attempting to rename network interface $matchedAdapterName to $interfaceAlias. ERROR: $_ ";
					$PVContext.WriteLog("Exception attempting to rename network interface: $($_) ");
				}
			}
		}
		
		Definition "IpAddress" -ExpectChildKey "IpAddress" {
			Test {
				$currentAdapter = $PVContext.CurrentKeyGroup;
				
				# Check the cached interface from the "Interface.Exists" test. If the interface wasn't found, we don't need to check the IP
				$extractionKey = "$($currentAdapter).matchedAdapter";
				$physicalAdapter = $PVContext.GetFacetState($extractionKey);
				
				if ($null -eq $physicalAdapter){
					return ""; # previous definition.test couldn't find the adapter in question - so the IP is moot. 
				}
				
				$targetConfig = $PVContext.GetFacetState("CurrentIpConfigurations") | Where-Object {
					$_.Index -eq ($physicalAdapter.Index)
				};
				
				$actualIp = "$($targetConfig.IPv4Address.IPAddress)/$($targetConfig.IPv4Address.PrefixLength)";  # cidr notation... 
				
				return $actualIp;
			}
			Configure {
				# if we weren't able to SET the adapter from previous steps, don't 'bother' trying to set the IP:
				$currentAdapter = $PVContext.CurrentKeyGroup;
				$actualAdapter = $PVContext.GetFacetState("$currentAdapter.ACTUAL_ADAPTER");
				
				if ($null -eq $actualAdapter) {
					throw "Expected Adapter [$currentAdapter] was NOT FOUND and/or failed to be configured as expected. Unable to Set IP Address.";
				}
				
				# Don't used cached IpConfig info anymore ... i.e., use 'live' - even if that means things take a few seconds: 
				$targetIpConfig = Get-ExistingIpConfigurations | Where-Object {
					$_.Index -eq ($actualAdapter.Index);
				};
				
				$realTimeCurrentIp = "$($targetIpConfig.IPv4Address.IPAddress)/$($targetIpConfig.IPv4Address.PrefixLength)";
				
				# re-check, small chance that the IP is what we want (and we merely renamed interfaces... )
				$configSpecifiedIp = $PVConfig.GetValue("Host.NetworkDefinitions.$currentAdapter.IpAddress");
				$ipChanged = $false;  # need to track this due to a goofy issue with DNS setup/configuration in some cases... 
				if ($realTimeCurrentIp -ne $configSpecifiedIp){
					
					$configSpecifiedGateway = $PVConfig.GetValue("Host.NetworkDefinitions.$currentAdapter.Gateway");

					$PVContext.WriteLog("Changing [if name] IP to [x.x.x.x/len] with gateway of [gateway]" , "Important");
					
					# Sadly, there's some SERIOUS ugly when it comes to changing IPs via Posh. See: https://etechgoodness.wordpress.com/2013/01/18/removing-an-adapter-gateway-using-powershell/  (i.e., need to remove the gateway as part of the change).
	# PICKUP/NEXT: need to streamline the code above a bit more --- and then make sure all of the args in the 3x calls below match actual VARIABLEs defined so far... 
#					Remove-NetIPAddress -InterfaceIndex ($actualAdapter.Index) -Confirm:$false;
#					Remove-NetRoute -InterfaceIndex ($actualAdapter.Index) -DestinationPrefix 0.0.0.0/0 -Confirm:$false; # see note above... 
#					
#					New-NetIPAddress -InterfaceIndex ($actualAdapter.Index) -IPAddress $expectedIpParts[0] -PrefixLength $expectedIpParts[1] -DefaultGateway $definedAdapter.Gateway;
				}
				
			}
		}
		
		Definition "Gateway" -ExpectChildKey "Gateway" {
			Test {
				$currentAdapter = $PVContext.CurrentKeyGroup;
				
				# Check the cached interface from the "Interface.Exists" test. If the interface wasn't found, we don't need to check the IP
				$extractionKey = "$($currentAdapter).matchedAdapter";
				$physicalAdapter = $PVContext.GetFacetState($extractionKey);
				
				if ($null -eq $physicalAdapter) {
					return ""; # previous definition.test couldn't find the adapter in question - so the IP is moot. 
				}
				
				$targetConfig = $PVContext.GetFacetState("CurrentIpConfigurations") | Where-Object {
					$_.Index -eq ($physicalAdapter.Index)
				};
				
				$gateway = $targetConfig.IPv4DefaultGateway.NextHop; # seems an odd way to do this... but, this is the correct way. 
				
				return $gateway;
			}
			Configure {
				# if we weren't able to SET the adapter from previous steps, don't 'bother' trying to set the gateway:
				$currentAdapter = $PVContext.CurrentKeyGroup;
				$actualAdapter = $PVContext.GetFacetState("$currentAdapter.ACTUAL_ADAPTER");
				
				if ($null -eq $actualAdapter) {
					throw "Expected Adapter [$currentAdapter] was NOT FOUND and/or failed to be configured as expected. Unable to Set IP Gateway.";
				}
				
				# start by rechecking the gateway 'now' - i.e., if there have been Interface or IP changes, the gateway is LIKELY correct/already set. 
			}
		}
		
		Definition "PrimaryDns" -ExpectChildKey "PrimaryDns" {
			Test {
				$currentAdapter = $PVContext.CurrentKeyGroup;
				
				# Check the cached interface from the "Interface.Exists" test. If the interface wasn't found, we don't need to check the IP
				$extractionKey = "$($currentAdapter).matchedAdapter";
				$physicalAdapter = $PVContext.GetFacetState($extractionKey);
				
				if ($null -eq $physicalAdapter) {
					return ""; # previous definition.test couldn't find the adapter in question - so the IP is moot. 
				}
				
				$targetConfig = $PVContext.GetFacetState("CurrentIpConfigurations") | Where-Object {
					$_.Index -eq ($physicalAdapter.Index)
				};
				
				[string[]]$dnsServers = $targetConfig.DNSServer.ServerAddresses;
				
				return $dnsServers[0];
			}
			Configure {
				# if we weren't able to SET the adapter from previous steps, don't 'bother' trying to set Primary DNS:
				$currentAdapter = $PVContext.CurrentKeyGroup;
				$actualAdapter = $PVContext.GetFacetState("$currentAdapter.ACTUAL_ADAPTER");
				
				if ($null -eq $actualAdapter) {
					throw "Expected Adapter [$currentAdapter] was NOT FOUND and/or failed to be configured as expected. Unable to Set Primary DNS.";
				}
				
				# TODO: in the IP change/configure section... there's an $ipsChanged = true/false value... 
				#   need to know about that DOWN IN HERE... 
			}
		}
		
		Definition "SecondaryDns" -ExpectChildKey "SecondaryDns" {
			Test {
				$currentAdapter = $PVContext.CurrentKeyGroup;
				
				# Check the cached interface from the "Interface.Exists" test. If the interface wasn't found, we don't need to check the IP
				$extractionKey = "$($currentAdapter).matchedAdapter";
				$physicalAdapter = $PVContext.GetFacetState($extractionKey);
				
				if ($null -eq $physicalAdapter) {
					return ""; # previous definition.test couldn't find the adapter in question - so the IP is moot. 
				}
				
				$targetConfig = $PVContext.GetFacetState("CurrentIpConfigurations") | Where-Object {
					$_.Index -eq ($physicalAdapter.Index)
				};
				
				[string[]]$dnsServers = $targetConfig.DNSServer.ServerAddresses;
				
				return $dnsServers[1];
			}
			Configure {
				# if we weren't able to SET the adapter from previous steps, don't 'bother' trying to set Secondary DNS:
				$currentAdapter = $PVContext.CurrentKeyGroup;
				$actualAdapter = $PVContext.GetFacetState("$currentAdapter.ACTUAL_ADAPTER");
				
				# TODO: Do I need to throw this IF there wasn't a secondary config specified in the Config?
				#  		Yeah... i think i simply return "" if there isn't a secondary value defined in the config... 
				#       ah... more importantly: why am i in here (in the CONFIGURE block) IF there isn't a secondary DNS addy defined? 
				#    MAYBE that means i need to REMOVE DNS[1] ? to make it look like the config? 
				if ($null -eq $actualAdapter) {
					throw "Expected Adapter [$currentAdapter] was NOT FOUND and/or failed to be configured as expected. Unable to Set Secondary DNS.";
				}
			}
		}
	}
}