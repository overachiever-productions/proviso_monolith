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

# TODO: this throws ugly errors when the user in question DOESN'T EXIST. e.g., assume I drop OVERACHIEVER\sqlserver into the .config for the SQL SErver service, but the actual name is: OVERACHIEVER\sqlservice
#  			rather than throwing: "Woah, that user doesn't exist, it throws "can't translate xyz" errors - which are UGLY
# 			so, need to add a quick CHECK to verify that the user exists. 
# 			hell, keep the same code, just un-inline it: 
# 				https://www.itprotoday.com/active-directory/find-sid-account-using-powershell
# 				https://techexpert.tips/powershell/powershell-get-user-sid/


function ConvertTo-WindowsSecurityIdentifier {
	param (
		[string]$Name
	);
	
	$translatedSid = (New-Object System.Security.Principal.NTAccount($Name)).Translate([System.Security.Principal.SecurityIdentifier]).value;
	
	return $translatedSid;
}