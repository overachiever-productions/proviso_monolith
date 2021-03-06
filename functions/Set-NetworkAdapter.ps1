Set-StrictMode -Version 1.0;

function Set-NetworkAdapter {
	
	# vNext: Possibly pass in the ID/name/Ordinal of a network adapter to use (i.e., which interface to modify)
	# 		at which point, the "Rename-NetworkInterface" method could/would be a bit different - it would be used to find and/or rename... 
	# 			but, when it was done, it'd pass either an object or interface name to use... 
	
	param (
		[Parameter(Mandatory = $true)]
		[ValidateScript({
				$_ -match [IPAddress]$_
			})]
		[string]$StaticIPAddress,
		[Parameter(Mandatory = $true)]
		[ValidateScript({
				$_ -match [IPAddress]$_
			})]
		[string]$GatewayIPAddress,
		[Parameter(Mandatory = $true)]
		[string[]]$DnsServerAddresses = @("208.67.222.222", "208.67.220.220"),
		[Parameter(Mandatory = $true)]
		[string]$PrefixLength = "24"
	);
	
	# Set the IP and DNS: 
	if (-not [string]::IsNullOrWhiteSpace($StaticIPAddress)) {
		New-NetIPAddress -InterfaceAlias "VM Network" -IPAddress $StaticIPAddress -PrefixLength $PrefixLength -DefaultGateway $GatewayIPAddress;
		Set-DnsClientServerAddress -InterfaceAlias "VM Network" -ServerAddresses ($DnsServerAddresses);
	}
}