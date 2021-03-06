Set-StrictMode -Version 1.0;

function Wait-UntilServiceStatus {
	
	# TODO: this SHOULD be capable of handling multiple services - i.e., 'chained' from command/line/inputs and such.
	# FUN: https://stackoverflow.com/a/34355759/11191
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$Service,
		[Parameter(Mandatory = $true)]
		# TODO: validate set of Running, Stopped, ??? 
		[string]$Status,
		[System.TimeSpan]$Timeout = '00:00:30'
	);
	
	# TODO: need to convert $Service - a string, into Get-Service instance... then do the logic below... 
	
	if ($Service.Status -ne $Status) {
		try{
			$Service.WaitForStatus($Status, $Timeout);
		}
		catch [System.ServiceProcess.TimeoutException] {
			throw "Timeout Exception Encountered - SQL Server Service could/would NOT stop within 30 seconds.";
		}
		catch {
			throw "Unexpected Problem Encountered: " + $PSItem.Exception.Message;
		}
	}
}