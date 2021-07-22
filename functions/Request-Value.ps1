Set-StrictMode -Version 1.0;

function Request-Value {
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$Message,
		[Parameter(Mandatory = $true)]
		[string]$DefaultValue
	);
	
	if (!($output = Read-Host ($Message -f $DefaultValue))) {
		$output = $DefaultValue
	}
	
	return $output;
}
