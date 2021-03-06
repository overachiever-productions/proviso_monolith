Set-StrictMode -Version 1.0;

function Rename-Machine {
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$TargetDomain,
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]$Credentials,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$NewMachineName
	);
	
	if ($TargetDomain -eq "WORKGROUP") {
		Rename-Computer -NewName $NewMachineName -Force; # - Restart
	}
	else {
		#$domainCreds = Get-Credential -Message "Please Provide Domain Admin Creds for $TargetDomain..." -UserName "Administrator";
		# Powershell 6+ requires ActiveDirectory module (see Install-ADManagementToolsForPowerShell6Plus) and New-ADComputer... 
		Add-Computer -DomainName $TargetDomain -NewName $NewMachineName -Credential $credentials; # - Restart
	}
}