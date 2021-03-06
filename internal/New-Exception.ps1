Set-StrictMode -Version 1.0;

function New-Exception {
	param (
		[Parameter(Mandatory = $true)]
		[string]$ErrorMessage,
		[Exception]$InnerException,
		[string]$ErrorId = "100",
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ErrorCategory]$ErrorCategory
	);
	
	[Exception]$exception = [Exception]::new($ErrorMessage);
	
	if ($InnerException) {
		$exception.InnerException = $InnerException;
	}
		
	[System.Management.Automation.ErrorRecord]$output = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $ErrorCategory, $null)
	
	return $output;
}