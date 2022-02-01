Set-StrictMode -Version 3.0;

[string]$script:ProvisoScriptRoot = $PSScriptRoot;
[PSCustomObject]$global:PVConfig = $null;
$global:PVExecuteActive = $false;
$global:PVRunBookActive = $false;

# 1. Import (.NET) classes (ordered to address dependency chains)
$classFiles = @(
	"$ProvisoScriptRoot\enums\AssertionsOutcome.cs"
	"$ProvisoScriptRoot\enums\ConfigurationsOutcome.cs"
	"$ProvisoScriptRoot\enums\DefinitionType.cs"
	"$ProvisoScriptRoot\enums\CredentialsType.cs"
	"$ProvisoScriptRoot\enums\SurfaceProcessingState.cs"
	"$ProvisoScriptRoot\enums\RebaseOutcome.cs"
	"$ProvisoScriptRoot\enums\ValidationErrorType.cs"
	"$ProvisoScriptRoot\enums\ValidationsOutcome.cs"
	"$ProvisoScriptRoot\classes\models\Assertion.cs"
	"$ProvisoScriptRoot\classes\models\Definition.cs"
	"$ProvisoScriptRoot\classes\models\Partition.cs"
	"$ProvisoScriptRoot\classes\models\Disk.cs"
	"$ProvisoScriptRoot\classes\models\Rebase.cs"
	"$ProvisoScriptRoot\classes\models\Runbook.cs"
	"$ProvisoScriptRoot\classes\models\Setup.cs"
	"$ProvisoScriptRoot\classes\models\Surface.cs"
	"$ProvisoScriptRoot\classes\processing\AssertionResult.cs"
	"$ProvisoScriptRoot\classes\processing\ConfigurationError.cs"
	"$ProvisoScriptRoot\classes\processing\ConfigurationResult.cs"
	"$ProvisoScriptRoot\classes\processing\RebaseResult.cs"
	"$ProvisoScriptRoot\classes\processing\ValidationError.cs"
	"$ProvisoScriptRoot\classes\processing\ValidationResult.cs"
	"$ProvisoScriptRoot\classes\processing\SurfaceProcessingResult.cs"
	"$ProvisoScriptRoot\classes\ProvisoCatalog.cs"
	"$ProvisoScriptRoot\classes\Orthography.cs"
	"$ProvisoScriptRoot\classes\DomainCredential.cs"
	"$ProvisoScriptRoot\classes\ProcessingContext.cs"
	"$ProvisoScriptRoot\classes\Formatter.cs"
);
Add-Type -Path $classFiles;

# 2. Internal Functions + DSL Support
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'internal/*.ps1') -Recurse -ErrorAction Stop))) {
	try {
		. $file.FullName;
	}
	catch {
		throw "Unable to dot source Internal Function: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 3. Public Functions / DSL
[string[]]$provisoPublicModuleMembers = @();
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'functions/*.ps1') -Recurse -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$provisoPublicModuleMembers += $file.Basename;
	}
	catch {
		throw "Unable to dot source Core Function: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 4. Import/Build Surfaces and dynamically create Validate|Configure|Document-<SurfaceName> funcs. 
Clear-SurfaceProxies -RootDirectory $ProvisoScriptRoot;
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'surfaces/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$currentSurface = $script:ProvisoCatalog.GetSurfaceByFileName(($file.Basename));
		if ($null -ne $currentSurface) {
			$surfaceName = $currentSurface.Name;
			$allowsRebase = $currentSurface.RebasePresent;
			
			Export-SurfaceProxyFunction -RootDirectory $ProvisoScriptRoot -SurfaceName $surfaceName;
			Export-SurfaceProxyFunction -RootDirectory $ProvisoScriptRoot -SurfaceName $surfaceName -Provision -AllowRebase:$allowsRebase;
		}
	}
	catch {
		throw "Unable to Import Surface: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 5. Import DSL Surface-Proxies (syntactic sugar):
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'surfaces/generated/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$provisoPublicModuleMembers += $file.Basename;
	}
	catch {
		throw "Unable to Import Surface Proxy-Function: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 6. Export
Export-ModuleMember -Function $provisoPublicModuleMembers;
Export-ModuleMember -Alias * -Function *;