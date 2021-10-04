Set-StrictMode -Version 1.0;

<# 
		b. within workflows (i.e., everywhere else) so that devs/users can see: 
			- .LastFacetProcessed 
			- .LastProcessingResult  (array of 1 or more results)

#>

## Testing:
#Add-Type -Path "D:\Dropbox\Repositories\proviso\classes\ProcessingContext.cs";
#. .\..\..\internal\Write-ProvisoLog.ps1;

$script:Context = [Proviso.Models.ProcessingContext]::Instance;
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

#$Context.WriteLog("this is a message", "Important");