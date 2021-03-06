Set-StrictMode -Version 1.0;

function Get-SqlServerPartnerServiceAccountName {
	
	# TODO: verify that admindb has already been deployed. 
	$output = Invoke-SqlCmd "SELECT service_account FROM PARTNER.master.sys.dm_server_services WHERE filename LIKE '%sqlservr.exe%'; ";
	
	return $output.service_account;
}