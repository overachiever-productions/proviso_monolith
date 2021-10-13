Set-StrictMode -Version 1.0;

$script:Context = [Proviso.ProcessingContext]::Instance;
$global:PVContext = $Context;

[ScriptBlock]$writeLog = {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Message,
		[ValidateSet("Critical", "Exception", "Important", "Verbose", "Debug")]
		[string]$Level = "Verbose"
	);
	
	if ((Get-InstalledModule -Name PSFramework) -or (Get-Module -Name PSFramework)) {
		Write-ProvisoLog -Message $Message -Level $Level;
	}
	else {
		Write-Host "$($Level.ToUpper()): $Message";
	}
}

Add-Member -InputObject $Context -MemberType ScriptMethod -Name WriteLog -Value $writeLog;