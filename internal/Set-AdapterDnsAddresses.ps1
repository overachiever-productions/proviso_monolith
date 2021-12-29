Set-StrictMode -Version 1.0;

function Set-AdapterDnsAddresses {
	param (
		[Parameter(Mandatory)]
		[int]$AdapterIndex,
		[Parameter(Mandatory)]
		$PrimaryDnsAddress,
		$SecondaryDnsAddress = $null
	);

	begin {
		
	};

	process {
		
		[string[]]$dnsServerAddresses = @();
		$dnsServerAddresses += $PrimaryDnsAddress;
		
		if ($null -ne $SecondaryDnsAddress) {
			$dnsServerAddresses += $SecondaryDnsAddress;
		}
		
		Set-DnsClientServerAddress -InterfaceIndex $AdapterIndex -ServerAddresses ($dnsServerAddresses) | Out-Null;
		
	};

	end {
		
	};
} 