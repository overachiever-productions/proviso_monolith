Set-StrictMode -Version 1.0;

function Install-SqlServerPowerShellModule {
	if (!(Get-Module -Name SqlServer -ListAvailable)) {
		
		# might need to look at using the -AllowClobber:$true as well.. (i.e., OLDER versions that might exist can/will cause problems? (which seems ODD if ... "SqlServer" module isn't installed.)
		
		Install-Module SqlServer -Confirm:$true -Force;
	}
}