Set-StrictMode -Version 1.0;

function New-IOPsDataCollector {
	
	# TODO: add params with defaults vs all this nasty hard-coding stuff.
	
	$traceName = "IOPs and IO Throughput";
	$traceFileDefinition = "C:\Scripts\resources\IOPs_DataCollector.xml";
	
	New-DataCollectorFromConfigFile -DataCollectorName $traceName -FullPathToXmlConfigFile $traceFileDefinition;
}