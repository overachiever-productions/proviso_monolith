Set-StrictMode -Version 1.0;

function Set-AdapterIpAddressAndGateway {
	
	param (
		[Parameter(Mandatory)]
		[int]$AdapterIndex,
		[Parameter(Mandatory)]
		$CidrIpAddress,
		[Parameter(Mandatory)]
		$GatewayIpAddress
	);
	
	begin {
		
	};
	
	process {
		# Sadly, IP config via POSH is a bit ugly - need to remove IP and routes then reset. 
		# 		See this for more info: https://etechgoodness.wordpress.com/2013/01/18/removing-an-adapter-gateway-using-powershell/ 
		
		[string[]]$ipParts = $CidrIpAddress -split "/";
		
		Remove-NetIPAddress -InterfaceIndex $AdapterIndex -Confirm:$false | Out-Null;
		Remove-NetRoute -InterfaceIndex $AdapterIndex -DestinationPrefix 0.0.0.0/0 -Confirm:$false | Out-Null;
		
		New-NetIPAddress -InterfaceIndex $AdapterIndex -IPAddress $ipParts[0] -PrefixLength $ipParts[1] -DefaultGateway $GatewayIpAddress | Out-Null;
	};
	
	end {
		
	};
}