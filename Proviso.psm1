Set-StrictMode -Version 3.0;

[string]$script:ProvisoScriptRoot = $PSScriptRoot;
[PSCustomObject]$global:PVConfig = $null;
$global:PVExecuteActive = $false;
$global:PVRunBookActive = $false;

# 1. Import (.NET) classes (ordered to address dependency chains)
$classFiles = @(
	"$ProvisoScriptRoot\enums\AssertionsOutcome.cs"
	"$ProvisoScriptRoot\enums\ConfigurationsOutcome.cs"
	"$ProvisoScriptRoot\enums\FacetType.cs"
	"$ProvisoScriptRoot\enums\CredentialsType.cs"
	"$ProvisoScriptRoot\enums\SurfaceProcessingState.cs"
	"$ProvisoScriptRoot\enums\RebaseOutcome.cs"
	"$ProvisoScriptRoot\enums\ValidationErrorType.cs"
	"$ProvisoScriptRoot\enums\ValidationsOutcome.cs"
	"$ProvisoScriptRoot\classes\models\Assertion.cs"
	"$ProvisoScriptRoot\classes\models\Facet.cs"
	"$ProvisoScriptRoot\classes\models\Partition.cs"
	"$ProvisoScriptRoot\classes\models\Disk.cs"
	"$ProvisoScriptRoot\classes\models\Rebase.cs"
	"$ProvisoScriptRoot\classes\models\Setup.cs"
	"$ProvisoScriptRoot\classes\models\Build.cs"
	"$ProvisoScriptRoot\classes\models\Deploy.cs"
	"$ProvisoScriptRoot\classes\models\Surface.cs"
	"$ProvisoScriptRoot\classes\models\Runbook.cs"
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

# 2. Internal Functions 
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'functions/internal/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
	}
	catch {
		throw "Unable to dot source Internal Function: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 3. Public Functions 
[string[]]$provisoPublicModuleMembers = @();
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'functions/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$provisoPublicModuleMembers += $file.Basename;
	}
	catch {
		throw "Unable to dot source Public Function: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 4. Internal and Public DSL:
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'dsl/internal/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
	}
	catch {
		throw "Unable to dot source Internal DSL Method: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'dsl/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$provisoPublicModuleMembers += $file.Basename;
	}
	catch {
		throw "Unable to dot source Public DSL Method: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 5. Import/Build Surfaces and dynamically create Validate|Configure|Document-<SurfaceName> funcs. 
Clear-ProvisoProxies -RootDirectory $ProvisoScriptRoot;
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'surfaces/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$currentSurface = $PVCatalog.GetSurfaceByFileName(($file.Basename));
		if ($null -ne $currentSurface) {
			$surfaceName = $currentSurface.Name;
			$allowsRebase = $currentSurface.RebasePresent;
			
			Generate-SurfaceProxies -RootDirectory $ProvisoScriptRoot -SurfaceName $surfaceName -AllowRebase:$allowsRebase;
			
			$provisoPublicModuleMembers += @("Validate-$surfaceName", "Configure-$surfaceName", "Run-$surfaceName");
		}
	}
	catch {
		throw "Unable to Import Surface: [$($file.FullName)]`rEXCEPTION: $_  `r`t$($_.ScriptStackTrace) ";
	}
}

# 6. Runbook Proxies
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'runbooks/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
	}
	catch {
		throw "Unable to Import Runbook File: [$($file.FullName)]`rEXCEPTION: $_  `r`t$($_.ScriptStackTrace) ";
	}
}

foreach ($runbook in $PVCatalog.GetRunbooks()) {
	try {
		Generate-RunbookProxies -RootDirectory $ProvisoScriptRoot -RunbookName ($runbook.Name);
		$provisoPublicModuleMembers += @("Evaluate-$($runbook.Name)", "Provision-$($runbook.Name)");
	}
	catch {
		throw "Error generating Runbook Proxies for [$($runbook.Name)]`rEXECEPTION: $_ `r`4$($_.ScriptStackTrace) ";
	}
}

# 7. Import Generated Proxies (syntactic sugar):
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'generated/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
	}
	catch {
		throw "Unable to Import Generated Proxy File: [$($file.FullName)]`rEXCEPTION: $_  `r`t$($_.ScriptStackTrace) ";
	}
}

# 8. Export
Export-ModuleMember -Function $provisoPublicModuleMembers;
Export-ModuleMember -Alias * -Function *;