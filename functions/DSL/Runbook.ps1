Set-StrictMode -Version 1.0;

<#




#>

function Runbook {
	
	param (
		[Parameter(Mandatory)]
		[Alias("For")]
		[string]$Name,
		[switch]$AllowReboot = $false,
		[string]$NextRunbook,
		[PSCustomObject]$Config
	);
	
	begin {
		
	};
	
	process {
		
	};
	
	end {
		
	};
}