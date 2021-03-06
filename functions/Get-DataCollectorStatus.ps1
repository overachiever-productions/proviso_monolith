Set-StrictMode -Version 1.0;

function Get-DataCollectorStatus {
	param (
		[string]$DataCollectorName
	);
	
	try {
		$state = Get-SMPerformanceCollector -CollectorName $DataCollectorName -ErrorAction Stop;
	}
	catch {
		$state = "NotFound";
	}
	
	return $state;
}