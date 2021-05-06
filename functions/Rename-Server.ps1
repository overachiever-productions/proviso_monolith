Set-StrictMode -Version 1.0;

function Rename-Server {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$NewMachineName,
		[switch]$AllowRestart = $true
	);
	
	begin {
		
	};
	
	process {
		
		Rename-Computer -NewName $NewMachineName -Force -Restart:$AllowRestart;
	};
	
	end {
		
	};
}