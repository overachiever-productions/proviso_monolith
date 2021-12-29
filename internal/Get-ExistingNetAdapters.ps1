Set-StrictMode -Version 1.0;

<#
	NOTE: without explicitly casting the output to [PSCustomObject], the following: 
			> $x = Get-ExistingNetAdapters;
			> Write-Host "x = $x " ... 
	Will yield: 
			"x = "
		i.e., not sure at all what's going on with .ToString() on CimInstance details or whatever... 
		So, capturing output + returning as a [PSCustomObject] seems to fix this issue.

#>

function Get-ExistingNetAdapters {
	$adapters = Get-NetAdapter | Select-Object Name, InterfaceDescription, @{ Name = "Index"; Expression = { $_.ifIndex	} }, Status;
	
	return [PSCustomObject]$adapters;
}