Set-StrictMode -Version 1.0;

filter Set-ProvisoConfigValueByKey {
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$Config,
		[Parameter(Mandatory)]
		[string]$Key,
		[Parameter(Mandatory)]
		[string]$Value
	);
	
	$keys = $Key -split "\.";
	$output = $null;
	# vNext: I presume there's a more elegant way to do this... but, it works and ... I don't care THAT much.
	switch ($keys.Count) {
		1 {
			$Config.($keys[0]) = $Value;
		}
		2 {
			$Config.($keys[0]).($keys[1]) = $Value;
		}
		3 {
			$Config.($keys[0]).($keys[1]).($keys[2]) = $Value;
		}
		4 {
			$Config.($keys[0]).($keys[1]).($keys[2]).($keys[3]) = $Value;
		}
		5 {
			$Config.($keys[0]).($keys[1]).($keys[2]).($keys[3]).($keys[4]) = $Value;
		}
		default {
			throw "Invalid Key. Too many key segments defined.";
		}
	}
}