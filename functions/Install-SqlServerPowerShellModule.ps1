Set-StrictMode -Version 1.0;

function Install-SqlServerPowerShellModule {
	if (!(Get-Module -Name SqlServer -ListAvailable)) {
		Install-Module SqlServer -Confirm:$false -Force | Out-Null;
	}
}