Set-StrictMode -Version 1.0;

function Get-ExistingAdapters {
	$adapters = Get-NetAdapter | Select-Object Name, InterfaceDescription, @{
		Name = "Index";  Expression = {
			$_.ifIndex
		}
	}, Status;
	
	return [PSCustomObject]$adapters;
}