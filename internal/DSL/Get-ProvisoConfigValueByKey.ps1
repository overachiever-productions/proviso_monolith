Set-StrictMode -Version 1.0;

filter Get-ProvisoConfigValueByKey {
	param (
		[PSCustomObject]$Config,
		[string]$Key
	);
	
	$keys = $Key -split "\.";
	$output = $null;
	# vNext: I presume there's a more elegant way to do this... but, it works and ... I don't care THAT much.
	switch ($keys.Count) {
		1 {
			$output = $Config.($keys[0]);
		}
		2 {
			$output = $Config.($keys[0]).($keys[1]);
		}
		3 {
			$output = $Config.($keys[0]).($keys[1]).($keys[2]);
		}
		4 {
			$output = $Config.($keys[0]).($keys[1]).($keys[2]).($keys[3]);
		}
		5 {
			$output = $Config.($keys[0]).($keys[1]).($keys[2]).($keys[3]).($keys[4]);
		}
		default {
			throw "Invalid Key. Too many key segments defined.";
		}
	}
	
	return $output;
}