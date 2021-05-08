Set-StrictMode -Version 1.0;

function Rename-SqlServerHostNameToMatchNetBiosServerName {
	
	# TODO: account for named instances.
	Invoke-SqlCmd -Query "EXEC admindb.dbo.update_server_name @PrintOnly = 0;";
}