Set-StrictMode -Version 1.0;

function New-SqlIniValue {
	param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$IniData,
		[Parameter(Mandatory = $true)]
		[string]$Key,
		[Parameter(Mandatory = $true)]
		[string]$Value,
		[string]$Group = "OPTIONS"
	);
	
	$currentOrdinal = $IniData._Ordinals.Keys | Sort-Object -Descending { $_ } | Select-Object -First 1;
	$ordinal = $currentOrdinal + 1;
	
	$IniData.$Group[$Key] = $Value;
	$IniData._ORDINALS[$ordinal] = "$($Group).$($Key)";
}