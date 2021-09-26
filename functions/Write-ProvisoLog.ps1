Set-StrictMode -Version 1.0;

<#
	NOTE that only Critical/Exception and Important will 'write' out to the host/console... 

#>

function Write-ProvisoLog{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$Message,
		[ValidateSet("Critical", "Exception", "Important", "Verbose", "Debug")]
		[string]$Level = "Verbose"
	);
	
	begin {
		if (-not ($script:proviso_log_initialized)) {
			# initialize... 
			Set-PSFLoggingProvider -Name logfile -Enabled:$true -FilePath "C:\Scripts\proviso_log.csv";
			$script:proviso_log_initialized = $true;
		}
	};
	
	process {
		if ($Level -eq "Exception") {
			$Level = "Critical"; # Exception is just an 'alias' for Critical i.e., a bit easier to remember/use when working in catch blocks/etc. 
		}
		
		
		Write-PSFMessage -Message $Message -Level $Level;
	};
}
$script:proviso_log_initialized = $false;