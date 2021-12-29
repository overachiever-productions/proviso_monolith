Set-StrictMode -Version 1.0;

<# 
	I MAY end up needing to be able to pull SIDs out of AD. 
	If so, the approach to adding AD into Windows Server (works on posh5 and posh7) is: 
		> Add-WindowsFeature RSAT-AD-PowerShell
				See: https://stackoverflow.com/a/17548616/11191
	(might need a reboot - so keep an eye on that). 

	Otherwise, once that's done, I can do: 
		> Get-ADUser "OVERACHIEVER\sqlservice" or whatever and ... golden. 

#>

filter ConvertTo-WindowsSecurityIdentifier {
	param (
		[Parameter(Mandatory)]
		[string]$Name
	);
	
	$ntObject = New-Object System.Security.Principal.NTAccount($Name) -ErrorAction SilentlyContinue;
	if ($null -eq $ntObject) {
		return $null;
	}
	
	try {
		$sid = $ntObject.Translate([System.Security.Principal.SecurityIdentifier]);
		return $sid;
	}
	catch {
		return $null;
	}
}