Set-StrictMode -Version 1.0;

Surface "NetworkAdapters" -Target "Host" {
	
	Assertions {
		Assert-UserIsAdministrator;
		
		Assert-HostIsWindows;
	}
	
	Aspect -IterateForScope "NetworkDefinitions" -OrderByChildKey "ProvisioningPriority" {
		Facet "Interface.Exists" -Expect $true -NoKey {
		# TODO: this facet should work with the definition below... 
		#Facet "Interface.Exists" -ExpectIteratorValue {
			Test {
				$expectedAdapterKey = $PVContext.CurrentObjectName;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
				$matchedAdapter = Get-ExistingNetAdapters | Where-Object { $_.Name -eq $expectedInterfaceName };
				
				if ($matchedAdapter -and ($matchedAdapter.Status -eq "Up")) {
					return $true;
				}
				
				return $false;
			}
			Configure {
				$expectedAdapterKey = $PVContext.CurrentObjectName;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				$assumableAdapters = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.AssumableIfNames");
				$availableAdapters = Get-ExistingNetAdapters;
				
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
		
		Facet "IpAddress" -Key "IpAddress" -ExpectKeyValue {
			Test {
				$expectedAdapterKey = $PVContext.CurrentObjectName;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
				$matchedAdapter = Get-ExistingNetAdapters | Where-Object {
					$_.Name -eq $expectedInterfaceName
				};
				
				if ($null -eq $matchedAdapter){
					return ""; 
				}
				
				$targetConfig = Get-ExistingIpConfigurations | Where-Object {
					$_.Index -eq ($matchedAdapter.Index)
				};
				
				$actualIp = "$($targetConfig.IPv4Address.IPAddress)/$($targetConfig.IPv4Address.PrefixLength)";  # cidr notation... 
				
				return $actualIp;
			}
			Configure {
				$expectedAdapterKey = $PVContext.CurrentObjectName;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
				$targetAdapterToConfigure = Get-ExistingNetAdapters | Where-Object {
					$_.Name -eq $expectedInterfaceName
				};
				
				if ($null -eq $targetAdapterToConfigure) {
					throw "Expected Adapter [$expectedAdapterKey] was NOT FOUND and/or failed to be configured as expected. Unable to Set IP Address.";
				}
				
				$targetIpConfig = Get-ExistingIpConfigurations | Where-Object {
					$_.Index -eq ($targetAdapterToConfigure.Index);
				};
				
				$realTimeCurrentIp = "$($targetIpConfig.IPv4Address.IPAddress)/$($targetIpConfig.IPv4Address.PrefixLength)";
				
				# re-check, small chance that the IP is ALREADY what is expected (and we merely renamed interfaces... )
				$configSpecifiedIp = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.IpAddress");

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
						
						Start-Sleep -Milliseconds 1200; # Let network settings 'take' (especially for domain joins) before continuing... 
					}
					catch {
						throw "Unexpected error attempting to change IP address for [$expectedInterfaceName]. ERROR: $_ ";
						$PVContext.WriteLog("Exception attempting to change IP address against [$expectedInterfaceName]: $($_) ");
					}
				}
			}
		}
		
		Facet "Gateway" -Key "Gateway" -ExpectKeyValue {
			Test {
				$expectedAdapterKey = $PVContext.CurrentObjectName;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
				$matchedAdapter = Get-ExistingNetAdapters | Where-Object {
					$_.Name -eq $expectedInterfaceName
				};
				
				if ($null -eq $matchedAdapter) {
					return "";
				}
				
				$targetConfig = Get-ExistingIpConfigurations | Where-Object {
					$_.Index -eq ($matchedAdapter.Index)
				};
				
				if ($null -eq $targetConfig) {
					return "";
				}
				
				$gateway = $targetConfig.IPv4DefaultGateway.NextHop; # nexthop is... the correct way to get the gateway.
				
				return $gateway;
			}
			Configure {
				$expectedAdapterKey = $PVContext.CurrentObjectName;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
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
						
						Start-Sleep -Milliseconds 1200; # Let network settings 'take' (especially for domain joins) before continuing... 
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
		
		Facet "PrimaryDns" -Key "PrimaryDns" -ExpectKeyValue {
			Test {
				$expectedAdapterKey = $PVContext.CurrentObjectName;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
				$matchedAdapter = Get-ExistingNetAdapters | Where-Object {
					$_.Name -eq $expectedInterfaceName
				};
				
				$targetConfig = Get-ExistingIpConfigurations | Where-Object {
					$_.Index -eq ($matchedAdapter.Index)
				};
				
				if ($null -eq $targetConfig) {
					return "";
				}
				
				[string[]]$dnsServers = $targetConfig.DNSServer.ServerAddresses;
				
				return $dnsServers[0];
			}
			Configure {
				# if we weren't able to SET the adapter from previous steps, don't 'bother' trying to set the gateway:
				$expectedAdapterKey = $PVContext.CurrentObjectName;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
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
		
		Facet "SecondaryDns" -Key "SecondaryDns" -ExpectKeyValue {
			Test {
				$expectedAdapterKey = $PVContext.CurrentObjectName;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
				$matchedAdapter = Get-ExistingNetAdapters | Where-Object {
					$_.Name -eq $expectedInterfaceName
				};
				
				$targetConfig = Get-ExistingIpConfigurations | Where-Object {
					$_.Index -eq ($matchedAdapter.Index)
				};
				
				if ($null -eq $targetConfig) {
					return "";
				}
				
				[string[]]$dnsServers = $targetConfig.DNSServer.ServerAddresses;
				
				return $dnsServers[1];
			}
			Configure {
				$expectedAdapterKey = $PVContext.CurrentObjectName;
				$expectedInterfaceName = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.InterfaceAlias");
				
				$matchedAdapter = Get-ExistingNetAdapters | Where-Object {
					$_.Name -eq $expectedInterfaceName
				};
				
				if ($null -eq $matchedAdapter) {
					throw "Expected Adapter [$expectedAdapterKey] was NOT FOUND and/or failed to be configured as expected. Unable to Set Secondary DNS.";
				}
				
				# NOTE: Set-AdapterDnsAddresses will REMOVE the secondary DNS if it's "" (or change it to whaver is specified in the config if not empty):
				$targetIpConfig = Get-ExistingIpConfigurations | Where-Object {
					$_.Index -eq ($matchedAdapter.Index);
				};
				
				[string[]]$dnsServers = $targetIpConfig.DNSServer.ServerAddresses;
				$currentRealTimeSecondaryDns = $dnsServers[1];
				
				$configSpecifiedSecondaryDns = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.SecondaryDns");
				
				if ($currentRealTimeSecondaryDns -ne $configSpecifiedSecondaryDns) {
					
					$PVContext.WriteLog("Changing Secondary DNS to [$configSpecifiedSecondaryDns] on [$expectedInterfaceName].", "Important");
					
					$configSpecifiedPrimaryDns = $PVConfig.GetValue("Host.NetworkDefinitions.$expectedAdapterKey.PrimaryDns");
					Set-AdapterDnsAddresses -AdapterIndex ($matchedAdapter.Index) -PrimaryDnsAddress $configSpecifiedPrimaryDns -SecondaryDnsAddress $configSpecifiedSecondaryDns;
				}
			}
		}
	}
}