Set-StrictMode -Version 1.0;

function Get-DataCollectorStatus {
	param (
		[string]$Name
	);
	
	try {
		# once again: total lies/confusion: https://docs.microsoft.com/en-us/powershell/scripting/whats-new/module-compatibility?view=powershell-7.1 
		#$state = Get-SMPerformanceCollector -CollectorName $Name -ErrorAction Stop;
		
		$state = "NotFound";
		
		$output = logman query;
		$pattern = "^(?i:" + $Name + ")\s+.+";
		
		$found = $output -match $pattern;
		if ($found) {
			[string[]]$parts = $found -split "\s+";
			$state = $parts[2];
		}
		
	}
	catch {
		$state = "NotFound";
	}
	
	return $state;
}