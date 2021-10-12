Set-StrictMode -Version 1.0;

<# 
		b. within workflows (i.e., everywhere else) so that devs/users can see: 
			- .LastFacetProcessed 
			- .LastProcessingResult  (array of 1 or more results)

#>

#region Testing
#[string]$script:ProvisoScriptRoot = "D:\Dropbox\Repositories\proviso";
#
## 1. Import (.NET) classes (ordered to address dependency chains)
#$classFiles = @(
#	"$ProvisoScriptRoot\enums\AssertionsOutcome.cs"
#	"$ProvisoScriptRoot\enums\ConfigurationsOutcome.cs"
#	"$ProvisoScriptRoot\enums\FacetProcessingState.cs"
#	"$ProvisoScriptRoot\enums\RebaseOutcome.cs"
#	"$ProvisoScriptRoot\enums\ValidationErrorType.cs"
#	"$ProvisoScriptRoot\enums\ValidationsOutcome.cs"
#	"$ProvisoScriptRoot\classes\models\Assertion.cs"
#	"$ProvisoScriptRoot\classes\models\Definition.cs"
#	"$ProvisoScriptRoot\classes\models\Rebase.cs"
#	"$ProvisoScriptRoot\classes\models\Facet.cs"
#	"$ProvisoScriptRoot\classes\models\FacetsCatalog.cs"
#	"$ProvisoScriptRoot\classes\processing\AssertionResult.cs"
#	"$ProvisoScriptRoot\classes\processing\ConfigurationError.cs"
#	"$ProvisoScriptRoot\classes\processing\ConfigurationResult.cs"
#	"$ProvisoScriptRoot\classes\processing\RebaseResult.cs"
#	"$ProvisoScriptRoot\classes\processing\ValidationError.cs"
#	"$ProvisoScriptRoot\classes\processing\ValidationResult.cs"
#	"$ProvisoScriptRoot\classes\processing\FacetProcessingResult.cs"
#	"$ProvisoScriptRoot\classes\DslStack.cs"
#	"$ProvisoScriptRoot\classes\ProcessingContext.cs"
#);
#Add-Type -Path $classFiles;
#
#. .\..\..\internal\Write-ProvisoLog.ps1;
#endregion

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

#region Testing
#$PVContext.WriteLog("this is a message", "Important");
#endregion