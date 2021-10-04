Set-StrictMode -Version 1.0;

<#
	NOTE that only 
		[Critical]/[Exception] 
		[Important] 
	will 'write' out to the host/console... 

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
		if (-not ($provisoLogInitialized)) {
			
			# vNEXT: this can/could be a 'global ($script:)' file-path that can/could be set by default to the path below and ... overridden by personal .config files and such.
			Set-PSFLoggingProvider -Name logfile -Enabled:$true -FilePath "C:\Scripts\proviso_log.csv";
			$provisoLogInitialized = $true;
		}
	};
	
	process {
		if ($Level -eq "Exception") {
			$Level = "Critical"; # Exception is just an 'alias' for Critical i.e., a bit easier to remember/use when working in catch blocks/etc. 
		}
		
		Write-PSFMessage -Message $Message -Level $Level;
	};
}
$script:provisoLogInitialized = $false;