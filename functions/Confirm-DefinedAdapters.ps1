Set-StrictMode -Version 1.0;

# vNEXT: throw in an additiona param that allows-for/enables CHANGES or just alerts/reports/throws IF there are errors - that way this code block 
#    can be used for both a. configuration/provisioning, and b) validation of network interfaces... 

# vNEXT: Possibly allow AssumableIfIds ... i.e., 0, 1, 3, 9... whatever... so'z we can assume an interface by ID vs name... 

function Confirm-DefinedAdapters {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$ServerDefinition,
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$CurrentAdapters,
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$CurrentIpConfiguration
	);
	
	begin {
		
	};
	
	process {
		# get an ordered list of DESIRED adapters (i.e., from config):
		$prioritizedAdapterDefinitions = New-Object "System.Collections.Generic.SortedDictionary[int, string]";
		
		$decrementKey = [int]::MaxValue;
		[string[]]$keys = $ServerDefinition.NetworkDefinitions.Keys;
		
		foreach ($definedAdapterName in $keys) {
			
			[string]$provisioningPriority = $ServerDefinition.NetworkDefinitions.$definedAdapterName.ProvisioningPriority;
			if ([string]::IsNullOrEmpty($provisioningPriority)) {
				$decrementKey = $decrementKey - 1;
				$provisioningPriority = $decrementKey;
			}
			
			$prioritizedAdapterDefinitions.Add($provisioningPriority, $definedAdapterName);
		}
		
		foreach ($adapterKey in $prioritizedAdapterDefinitions.GetEnumerator()) {
			
			$adapterName = $adapterKey.Value;
			$definedAdapter = $ServerDefinition.NetworkDefinitions.$adapterName;
			$interfaceName = $ServerDefinition.NetworkDefinitions.$adapterName.InterfaceAlias;
			
			# ensure that the desired/defined adapter exists: 
			$actualAdapter = $CurrentAdapters | Where-Object {$_.Name -eq $interfaceName };
			
			# if it doesn't, see if we have targets to 'commandeer' from:
			if ($actualAdapter -eq $null){
				[string[]]$targetableAdapters = $definedAdapter.AssumableIfNames;
				
				$matchedAdapter = $null;
				foreach ($assumableTarget in $targetableAdapters){
					$matchedAdapter = $CurrentAdapters | Where-Object {
						$_.Name -eq $assumableTarget
					};
					
					if ($matchedAdapter -ne $null) {
						break;
					}
				}
				
				if ($matchedAdapter -eq $null) {
					throw "Network Adapter Name $adapterName specified in configuration NOT FOUND and no Assumable Interface Names were matched. Network provisioning is terminating.";
				}
				
				try {
					$matchedAdapterName = $matchedAdapter.Name;
					
					Write-ProvisoLog  -Message "Renaming '$matchedAdapterName' to '$interfaceName'. " -Level Important;
					Rename-NetAdapter -Name $matchedAdapterName -NewName $interfaceName;
					
					$actualAdapter = $CurrentAdapters | Where-Object {
						$_.Name -eq $matchedAdapterName
					};
				}
				catch {
					throw "Unexpected error attempting to rename network interface $matchedAdapterName to $adapterName. ";
				}
			}
			
			# validate IP, gateway, DNS, etc.
			$interfaceIndex = $actualAdapter.Index;  # we might've renamed an existing interface - so... use Index vs name for following checks.
			$targetIpConfig = $CurrentIpConfiguration | Where-Object {
				$_.Index -eq $interfaceIndex
			};
			
			if ($targetIpConfig -eq $null) {
				throw "Unexpected exception when working with Adapter at Index $interfaceIndex - Target should exist but is NULL. ";
			}
			
			# actual:
			$ip = $targetIpConfig.IPv4Address.IPAddress;
			$length = $targetIpConfig.IPv4Address.PrefixLength;
			$gateway = $targetIpConfig.IPv4DefaultGateway.NextHop; # seriously, odd way of doing that... 
			
			[string[]]$dnsServers = $targetIpConfig.DNSServer.ServerAddresses;
			$dns1 = $dnsServers[0];
			
			$dns2 = $null;
			if ($dnsServers.Count -gt 1) {
				$dns2 = $dnsServers[1];
			}
			
			# expected + comparisons/changes:
			[string[]]$expectedIpParts = $definedAdapter.IpAddress -split "/";
			
			$ipsChanged = $false;
			if (($ip -ne $expectedIpParts[0]) -or ($length -ne $expectedIpParts[1]) -or ($gateway -ne $definedAdapter.Gateway)) {
				
				Write-ProvisoLog -Message "Changing the IP to $($expectedIpParts[0])/$($expectedIpParts[1]) with a gateway of $($definedAdapter.Gateway)." -Level Important;
				
				Remove-NetIPAddress -InterfaceIndex $interfaceIndex -Confirm:$false;
				Remove-NetRoute -InterfaceIndex $interfaceIndex -DestinationPrefix 0.0.0.0/0 -Confirm:$false; # sigh. remove the gateway too: https://etechgoodness.wordpress.com/2013/01/18/removing-an-adapter-gateway-using-powershell/
				
				New-NetIPAddress -InterfaceIndex $interfaceIndex -IPAddress $expectedIpParts[0] -PrefixLength $expectedIpParts[1] -DefaultGateway $definedAdapter.Gateway;
				$ipsChanged = $true;
			}
			
			$definedDns2 = $null;
			if ($definedAdapter["SecondaryDns"] -ne $null) {
				$definedDns2 = $definedAdapter.SecondaryDns;
			}
			
			# NOTE: If we change from DHCP to STATIC in same SUBNET, default DNS (e.g., 10.0.0.1) would have already been set - so $dns1 would equal $defined.Primary)... but changing IPs CLEARS/RESETS DNS - so... we end up with '' for primary DNS without making changes if/when IPs change.
			if (($ipsChanged) -or ($dns1 -ne $definedAdapter.PrimaryDns) -or ($dns2 -ne $definedDns2)) {
				[string[]]$dns = @($definedAdapter.PrimaryDns);
				if ($definedDns2 -ne $null) {  # vNEXT: this is all clunky/hacky... i.e., I create $definedDNs2 above... and then check it here... seems smelly. 
					$dns += $definedDns2
				}
				
				Write-ProvisoLog  -Message "Changing DNS servers to $dns . " -Level Important;
				Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses ($dns);
			}
			
		}
		
	};
	
	end {
		
	};
}