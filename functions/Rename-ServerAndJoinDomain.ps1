Set-StrictMode -Version 1.0;

function Rename-ServerAndJoinDomain {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$TargetDomain,
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]$Credentials,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$NewMachineName,
		[switch]$AllowRestart = $true
	);
	
	begin {
		
	};
	
	process {
		Add-Computer -DomainName $TargetDomain -NewName $NewMachineName -Credential $credentials -Restart:$AllowRestart;
	};
	
	end {
		
	};
}