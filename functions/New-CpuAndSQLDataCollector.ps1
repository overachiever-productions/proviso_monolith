Set-StrictMode -Version 1.0;

function New-CpuAndSQLDataCollector {
	
	# TODO: add params with defaults vs all this nasty hard-coding stuff.
	
	$traceName = "CPU and SQL Metrics";
	$traceFileDefinition = "C:\Scripts\resources\CPU-SQL_DataCollector.xml";
	
	New-DataCollectorFromConfigFile -DataCollectorName $traceName -FullPathToXmlConfigFile $traceFileDefinition;
}