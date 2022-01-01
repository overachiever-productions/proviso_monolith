Set-StrictMode -Version 1.0;

filter Get-ExistingSqlServerInstanceNames {
	
	[string[]]$output = @();
	
	$key = Get-Item 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server' -ErrorAction SilentlyContinue;
	if (($key -eq $null) -or ([string]::IsNullOrEmpty($key.Property))) {
		return $output;
	}
	
	[string[]]$output = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances;
	return $output;
}