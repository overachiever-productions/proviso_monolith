Set-StrictMode -Version 1.0;

function Unblock-FirewallForSqlServer {
	[CmdletBinding()]
	param (
		[switch]$EnableDAC = $true,
		[switch]$EnableMirroring,
		[switch]$Silent
	);
	
	# TODO: this if/else logic sucks... 
	if ($Silent) {
		New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 1433 | Out-Null;
		
		if ($EnableDAC) {
			New-NetFirewallRule -DisplayName "SQL Server - DAC" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 1434 | Out-Null;
		}
		
		if ($EnableMirroring) {
			New-NetFirewallRule -DisplayName "SQL Server - Mirroring" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5022 | Out-Null;
		}
	}
	else {
		New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 1433;
		
		if ($EnableDAC) {
			New-NetFirewallRule -DisplayName "SQL Server - DAC" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 1434;
		}
		
		if ($EnableMirroring) {
			New-NetFirewallRule -DisplayName "SQL Server - Mirroring" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5022;
		}
	}
}