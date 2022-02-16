Set-StrictMode -Version 1.0;

filter New-ConfigSecret {
	[Alias("ConfigSecret")]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string]$Key,
		[Parameter(Mandatory, Position = 1)]
		[string]$Value
	)
	
	return [PSCustomObject]@{
		Key   = $Key
		Value = $Value
	};
}