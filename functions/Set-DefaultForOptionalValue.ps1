Set-StrictMode -Version 1.0;

function Set-DefaultForOptionalValue {
	param (
		[string]$OptionalValue,
		[Parameter(Mandatory = $true)]
		[string]$DefaultValue
	);
	
	if ([string]::IsNullOrEmpty($OptionalValue)) {
		$OptionalValue = $DefaultValue;
	}
	
	return $OptionalValue;
}