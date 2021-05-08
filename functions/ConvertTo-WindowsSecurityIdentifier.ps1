Set-StrictMode -Version 1.0;

function ConvertTo-WindowsSecurityIdentifier {
	
	param (
		[string]$Name
	);
	
	$translatedSid = (New-Object System.Security.Principal.NTAccount($Name)).Translate([System.Security.Principal.SecurityIdentifier]).value;
	
	return $translatedSid;
}