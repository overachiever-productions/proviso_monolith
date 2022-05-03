Set-StrictMode -Version 3.0;

[string]$script:ProvisoScriptRoot = $PSScriptRoot;
$global:PVExecuteActive = $false;
$global:PVRunBookActive = $false;

$script:be8c742fDefaultConfigData = $null;

# 1. Import (.NET) classes (ordered to address dependency chains)
$classFiles = @(
	"$ProvisoScriptRoot\clr\Proviso.Models\Enums\AssertionsOutcome.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Enums\ConfigurationsOutcome.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Enums\FacetType.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Enums\CredentialsType.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Enums\SurfaceProcessingState.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Enums\RebaseOutcome.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Enums\ValidationErrorType.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Enums\ValidationsOutcome.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Models\Assertion.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Models\Facet.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Models\Rebase.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Models\Setup.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Models\Build.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Models\Deploy.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Models\Surface.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Models\Runbook.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\DomainModels\Partition.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\DomainModels\Disk.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Processing\AssertionResult.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Processing\ConfigurationError.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Processing\ConfigurationResult.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Processing\RebaseResult.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Processing\ValidationError.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Processing\ValidationResult.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Processing\SurfaceProcessingResult.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\ProvisoCatalog.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Orthography.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\DomainCredential.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\ProcessingContext.cs"
	"$ProvisoScriptRoot\clr\Proviso.Models\Formatter.cs"
);
Add-Type -Path $classFiles;

# 2. Internal Functions 
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'internal/*.ps1') -Recurse -ErrorAction Stop))) {
	try {
		. $file.FullName;
	}
	catch {
		throw "Unable to dot source Internal Function: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}



# 3. Public Functions 
[string[]]$provisoPublicModuleMembers = @();
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'functions/*.ps1') -Recurse -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$provisoPublicModuleMembers += $file.Basename;
	}
	catch {
		throw "Unable to dot source Public Function: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 4. Import/Build Surfaces and dynamically create Validate|Configure|Document-<SurfaceName> funcs. 
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

# 5. Runbook Proxies
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

# 6. Import Generated Proxies (syntactic sugar):
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'generated/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
	}
	catch {
		throw "Unable to Import Generated Proxy File: [$($file.FullName)]`rEXCEPTION: $_  `r`t$($_.ScriptStackTrace) ";
	}
}

# 7. Export
Export-ModuleMember -Function $provisoPublicModuleMembers;
Export-ModuleMember -Alias * -Function *;