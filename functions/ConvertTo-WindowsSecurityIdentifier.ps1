Set-StrictMode -Version 1.0;

function ConvertTo-WindowsSecurityIdentifier {
	
	param (
		[string]$DomainUser
	);
	
	$translatedSid = (New-Object System.Security.Principal.NTAccount($DomainUser)).Translate([System.Security.Principal.SecurityIdentifier]).value;
	
	return $translatedSid;
}