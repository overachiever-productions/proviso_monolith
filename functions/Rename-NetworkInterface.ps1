Set-StrictMode -Version 1.0;

function Rename-NetworkInterface {
	
	# vNext: use params here to specify behavior if/when we either don't find matches and/or there are > 1 potential matches. 
	# 		i.e., should we throw and error and abort? or ... interactively ask the user and so on... 
	
	# Rename Net Adapter if/as needed: 
	$vmNetwork = Get-NetAdapter | Where-Object {
		$_.Name -eq "VM Network"
	}
	
	if ($null -eq $vmNetwork) {
		$eth0 = Get-NetAdapter | Where-Object {
			$_.InterfaceDescription -like 'vmxnet*' -and $_.Name -like "Ethernet0*"
		}
		
		# vNEXT: if $eth0.Count <> 1 (i.e., 0 or > 1), either throw an error or force user to PICK an interface to modify... (i.e., give them info on which interfaces matched and their current IPs/networks and so on... )
		
		if ($eth0) {
			$interfaceName = $eth0.Name;
			Write-Host "Renaming '$interfaceName' Adapter to 'VM Network'."
			Rename-NetAdapter -Name $interfaceName -NewName 'VM Network'
		}
		else {
			throw "Unable to find matching Interface ('Ethernet 0') for modifications.";
		}
		
	}
}