Set-StrictMode -Version 1.0;

function Get-InstalledSqlServerInstanceNames {
	[string[]]$output = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances;
	return $output;
}