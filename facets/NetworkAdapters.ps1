Set-StrictMode -Version 1.0;

Facet -For "NetworkAdapters" {
	
	Setup {
		$adapters = Get-ExistingNetAdapters;
		$ipConfigs = Get-ExistingIpConfigurations;
		
		$PVContext.AddFacetState("AvailableAdapters", $adapters);
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
				$expectedAdapterKey = $PVContext.CurrentKeyGroup;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
				$availableAdapters = $PVContext.GetFacetState("AvailableAdapters");
				$matchedAdapter = $availableAdapters | Where-Object { $_.Name -eq $expectedInterfaceName };
				
				if ($matchedAdapter -and ($matchedAdapter.Status -eq "Up")) {
					$PVContext.AddFacetState("$($expectedAdapterKey).matchedAdapter", $matchedAdapter);
					return $true;
				}
				
				return $false;
			}
			Configure {
				$expectedAdapterKey = $PVContext.CurrentKeyGroup;
				
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				$assumableAdapters = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.AssumableIfNames");
								
				$availableAdapters = $PVContext.GetFacetState("AvailableAdapters");
				
				$matchedAdapter = $null;
				foreach ($assumableTarget in $assumableAdapters) {
					$matchedAdapter = $availableAdapters | Where-Object {
						($_.Name -eq $assumableTarget) -and ($_.Status -eq "Up")
					};
					
					if ($matchedAdapter -ne $null) {
						break;
					}
				}
				
				if ($matchedAdapter -eq $null) {
					throw "Expected Adapter [$expectedInterfaceName] was NOT FOUND and no matching AssumableIfNames were matched. Network provisioning is terminating.";
				}
				
				try {
					$matchedAdapterName = $matchedAdapter.Name;
					
					$PVContext.WriteLog("Renaming [$matchedAdapterName] to [$expectedInterfaceName].", "Important");
					Rename-NetAdapter -Name $matchedAdapterName -NewName $expectedInterfaceName;
				}
				catch {
					throw "Unexpected error attempting to rename network interface $matchedAdapterName to $interfaceAlias. ERROR: $_ ";
					$PVContext.WriteLog("Exception attempting to rename network interface: $($_) ");
				}
			}
		}
		
		Definition "IpAddress" -ExpectChildKey "IpAddress" {
			Test {
				$expectedAdapterKey = $PVContext.CurrentKeyGroup;
				
				# Check the cached interface from the "Interface.Exists" test. If the interface wasn't found, we don't need to check the IP
				$physicalAdapter = $PVContext.GetFacetState("$($expectedAdapterKey).matchedAdapter");
				
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
				$expectedAdapterKey = $PVContext.CurrentKeyGroup;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
				# Don't used cached adpter info - we MAY have just renamed/changed an adapter - i.e., start 'fresh':
				$targetAdapterToConfigure = Get-ExistingNetAdapters | Where-Object {
					$_.Name -eq $expectedInterfaceName
				};
				
				if ($null -eq $targetAdapterToConfigure) {
					throw "Expected Adapter [$expectedAdapterKey] was NOT FOUND and/or failed to be configured as expected. Unable to Set IP Address.";
				}
				
				# Don't used cached IpConfig info anymore ... i.e., use 'live' - even if that means things take a few seconds: 
				$targetIpConfig = Get-ExistingIpConfigurations | Where-Object {
					$_.Index -eq ($targetAdapterToConfigure.Index);
				};
				
				$realTimeCurrentIp = "$($targetIpConfig.IPv4Address.IPAddress)/$($targetIpConfig.IPv4Address.PrefixLength)";
				
				# re-check, small chance that the IP is ALREADY what is expected (and we merely renamed interfaces... )
				$configSpecifiedIp = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.IpAddress");
				$ipChanged = $false;  # need to track this due to a goofy issue with DNS setup/configuration in some cases... 
				if ($realTimeCurrentIp -ne $configSpecifiedIp){
					
					$configSpecifiedGateway = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.Gateway");
					[string[]]$configSpecifiedIpParts = $configSpecifiedIp -split "/";
										
					$PVContext.WriteLog("Changing [$expectedInterfaceName] IP to [$configSpecifiedIp] with gateway of [$configSpecifiedGateway]." , "Important");
					try {
						Set-AdapterIpAddressAndGateway -AdapterIndex ($targetAdapterToConfigure.Index) -CidrIpAddress $configSpecifiedIp -GatewayIpAddress $configSpecifiedGateway;
						
						# sadly, IF we happened to change from dynamic to STATIC IPs (within the same subnet), DNS entries will have been nuked/removed, so: 
						$configSpecifiedPrimaryDns = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.PrimaryDns");
						$configSpecifiedSecondaryDns = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.SecondaryDns");;
						Set-AdapterDnsAddresses -AdapterIndex ($targetAdapterToConfigure.Index) -PrimaryDnsAddress $configSpecifiedPrimaryDns -SecondaryDnsAddress $configSpecifiedSecondaryDns;
					}
					catch {
						throw "Unexpected error attempting to change IP address for [$expectedInterfaceName]. ERROR: $_ ";
						$PVContext.WriteLog("Exception attempting to change IP address against [$expectedInterfaceName]: $($_) ");
					}
				}
			}
		}
		
		Definition "Gateway" -ExpectChildKey "Gateway" {
			Test {
				$expectedAdapterKey = $PVContext.CurrentKeyGroup;
				
				# Check the cached interface from the "Interface.Exists" test. If the interface wasn't found, we don't need to check the IP
				$physicalAdapter = $PVContext.GetFacetState("$($expectedAdapterKey).matchedAdapter");
				
				if ($null -eq $physicalAdapter) {
					return ""; # previous definition.test couldn't find the adapter in question - so the IP is moot. 
				}
				
				$targetConfig = $PVContext.GetFacetState("CurrentIpConfigurations") | Where-Object {
					$_.Index -eq ($physicalAdapter.Index)
				};
				
				if ($null -eq $targetConfig) {
					return "";
				}
				
				$gateway = $targetConfig.IPv4DefaultGateway.NextHop; # seems an odd way to do this... but, this is the correct way. 
				
				return $gateway;
			}
			Configure {
				# if we weren't able to SET the adapter from previous steps, don't 'bother' trying to set the gateway:
				$expectedAdapterKey = $PVContext.CurrentKeyGroup;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
				# Don't used cached adpter info - we MAY have just renamed/changed an adapter - i.e., start 'fresh':
				$targetAdapterToConfigure = Get-ExistingNetAdapters | Where-Object {
					$_.Name -eq $expectedInterfaceName
				};
				
				if ($null -eq $targetAdapterToConfigure) {
					throw "Expected Adapter [$expectedAdapterKey] was NOT FOUND and/or failed to be configured as expected. Unable to Set IP Gateway.";
				}
				
				# start by rechecking the gateway 'now' - i.e., if there have been Interface or IP changes, the gateway is LIKELY correct/already set. 
				$targetIpConfig = Get-ExistingIpConfigurations | Where-Object {
					$_.Index -eq ($targetAdapterToConfigure.Index);
				};
				
				$realTimeCurrentGateway = $targetIpConfig.IPv4DefaultGateway.NextHop;
				$configSpecifiedGateway = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.Gateway");
				
				if ($realTimeCurrentGateway -ne $configSpecifiedGateway) {
					$configSpecifiedIp = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.IpAddress");
					
					$PVContext.WriteLog("Changing [$expectedInterfaceName] Gateway to [$configSpecifiedGateway].", "Important");
					try {
						Set-AdapterIpAddressAndGateway -AdapterIndex ($targetAdapterToConfigure.Index) -CidrIpAddress $configSpecifiedIp -GatewayIpAddress $realTimeCurrentGateway;
						
						# sadly, IF we happened to change from dynamic to STATIC IPs (within the same subnet), DNS entries will have been nuked/removed, so: 
						$configSpecifiedPrimaryDns = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.PrimaryDns");
						$configSpecifiedSecondaryDns = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.SecondaryDns");;
						Set-AdapterDnsAddresses -AdapterIndex ($targetAdapterToConfigure.Index) -PrimaryDnsAddress $configSpecifiedPrimaryDns -SecondaryDnsAddress $configSpecifiedSecondaryDns;
					}
					catch {
						catch {
							throw "Unexpected error attempting to change GATEWAY address for [$expectedInterfaceName]. ERROR: $_ ";
							$PVContext.WriteLog("Exception attempting to change GATEWAY address against [$expectedInterfaceName]: $($_) ");
						}
					}
				}
			}
		}
		
		Definition "PrimaryDns" -ExpectChildKey "PrimaryDns" {
			Test {
				$expectedAdapterKey = $PVContext.CurrentKeyGroup;
				
				# Check the cached interface from the "Interface.Exists" test. If the interface wasn't found, we don't need to check the IP
				$physicalAdapter = $PVContext.GetFacetState("$($expectedAdapterKey).matchedAdapter");
				
				if ($null -eq $physicalAdapter) {
					return ""; # previous definition.test couldn't find the adapter in question - so the IP is moot. 
				}
				
				$targetConfig = $PVContext.GetFacetState("CurrentIpConfigurations") | Where-Object {
					$_.Index -eq ($physicalAdapter.Index)
				};
				
				if ($null -eq $targetConfig) {
					return "";
				}
				
				[string[]]$dnsServers = $targetConfig.DNSServer.ServerAddresses;
				
				return $dnsServers[0];
			}
			Configure {
				# if we weren't able to SET the adapter from previous steps, don't 'bother' trying to set the gateway:
				$expectedAdapterKey = $PVContext.CurrentKeyGroup;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
				# Don't used cached adpter info - we MAY have just renamed/changed an adapter AND possibly just set/reset DNS entries due to IP address changes/etc. 
				$targetAdapterToConfigure = Get-ExistingNetAdapters | Where-Object {
					$_.Name -eq $expectedInterfaceName
				};
				
				if ($null -eq $targetAdapterToConfigure) {
					throw "Expected Adapter [$expectedAdapterKey] was NOT FOUND and/or failed to be configured as expected. Unable to Set Primary DNS.";
				}
				
				$targetIpConfig = Get-ExistingIpConfigurations | Where-Object {
					$_.Index -eq ($targetAdapterToConfigure.Index);
				};
				
				[string[]]$dnsServers = $targetIpConfig.DNSServer.ServerAddresses;
				$currentRealTimePrimaryDns = $dnsServers[0];
				
				$configSpecifiedPrimaryDns = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.PrimaryDns");
				
				if ($currentRealTimePrimaryDns -ne $configSpecifiedPrimaryDns) {
					
					$PVContext.WriteLog("Changing Primary DNS to [$configSpecifiedPrimaryDns] on [$expectedInterfaceName].", "Important");
					
					$configSpecifiedSecondaryDns = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.SecondaryDns");;
					Set-AdapterDnsAddresses -AdapterIndex ($targetAdapterToConfigure.Index) -PrimaryDnsAddress $configSpecifiedPrimaryDns -SecondaryDnsAddress $configSpecifiedSecondaryDns;
				}
			}
		}
		
		Definition "SecondaryDns" -ExpectChildKey "SecondaryDns" {
			Test {
				$expectedAdapterKey = $PVContext.CurrentKeyGroup;
				
				# Check the cached interface from the "Interface.Exists" test. If the interface wasn't found, we don't need to check the IP
				$physicalAdapter = $PVContext.GetFacetState("$($expectedAdapterKey).matchedAdapter");
				
				if ($null -eq $physicalAdapter) {
					return ""; # previous definition.test couldn't find the adapter in question - so the IP is moot. 
				}
				
				$targetConfig = $PVContext.GetFacetState("CurrentIpConfigurations") | Where-Object {
					$_.Index -eq ($physicalAdapter.Index)
				};
				
				if ($null -eq $targetConfig) {
					return "";
				}
				
				[string[]]$dnsServers = $targetConfig.DNSServer.ServerAddresses;
				
				return $dnsServers[1];
			}
			Configure {
				# if we weren't able to SET the adapter from previous steps, don't 'bother' trying to set the gateway:
				$expectedAdapterKey = $PVContext.CurrentKeyGroup;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
				# Don't used cached adpter info - we MAY have just renamed/changed an adapter - i.e., start 'fresh':
				$targetAdapterToConfigure = Get-ExistingNetAdapters | Where-Object {
					$_.Name -eq $expectedInterfaceName
				};
				
				if ($null -eq $targetAdapterToConfigure) {
					throw "Expected Adapter [$expectedAdapterKey] was NOT FOUND and/or failed to be configured as expected. Unable to Set Secondary DNS.";
				}
				
				# NOTE: Set-AdapterDnsAddresses will REMOVE the secondary DNS if it's "" (or change it to whaver is specified in the config if not empty):
				$targetIpConfig = Get-ExistingIpConfigurations | Where-Object {
					$_.Index -eq ($targetAdapterToConfigure.Index);
				};
				
				[string[]]$dnsServers = $targetIpConfig.DNSServer.ServerAddresses;
				$currentRealTimeSecondaryDns = $dnsServers[1];
				
				# TODO: account for secondary DNS being EMPTY/NULL/NOT-SET... 
				
				$configSpecifiedSecondaryDns = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.SecondaryDns");;
				
				if ($currentRealTimeSecondaryDns -ne $configSpecifiedSecondaryDns) {
					
					$PVContext.WriteLog("Changing Secondary DNS to [$configSpecifiedSecondaryDns] on [$expectedInterfaceName].", "Important");
					
					$configSpecifiedPrimaryDns = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.PrimaryDns");
					Set-AdapterDnsAddresses -AdapterIndex ($targetAdapterToConfigure.Index) -PrimaryDnsAddress $configSpecifiedPrimaryDns -SecondaryDnsAddress $configSpecifiedSecondaryDns;
				}
			}
		}
	}
}