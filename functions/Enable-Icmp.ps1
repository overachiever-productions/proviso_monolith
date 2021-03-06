Set-StrictMode -Version 1.0;

function Enable-Icmp {
	# vNext: include a switch to control ICMP rules for IPv6... 
	
	Set-NetFirewallRule -Name "FPS-ICMP4-ERQ-In" -Enabled true; # this is built into Windows 2019+ for older OSes I might have to use something similar to the following: 
	# New-NetFirewallRule -DisplayName "Allow inbound ICMPv4" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -RemoteAddress <localsubnet> -Action Allow
}