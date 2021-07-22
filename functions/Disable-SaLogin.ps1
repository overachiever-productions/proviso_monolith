Set-StrictMode -Version 1.0;

function Disable-SaLogin {
	# vNEXT: add a $Credentials object... 
	
	Invoke-SqlCmd -Query "ALTER LOGIN [sa] DISABLE; ";
}