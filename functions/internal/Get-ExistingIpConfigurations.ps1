Set-StrictMode -Version 1.0;

function Get-ExistingIpConfigurations {
	$data = Get-NetIPConfiguration | Select-Object @{
		Name = "Name"; Expression = {
			$_.InterfaceAlias
		}
	},
												   @{
		Name = "Description"; Expression = {
			$_.InterfaceDescription
		}
	}, @{
		Name = "Index"; Expression = {
			$_.InterfaceIndex
		}
	}, IPv4Address, IPv4DefaultGateway, DNSServer, "NetProfile.Name";
	
	return [PSCustomObject]$data;
}