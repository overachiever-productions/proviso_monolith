Set-StrictMode -Version 3.0;

[string]$script:ProvisoScriptRoot = $PSScriptRoot;
[PSCustomObject]$global:PVConfig = $null;
$global:PVExecuteActive = $false;
$global:PVRunBookActive = $false;

# 1. Import (.NET) classes (ordered to address dependency chains)
$classFiles = @(
	"$ProvisoScriptRoot\enums\AssertionsOutcome.cs"
	"$ProvisoScriptRoot\enums\ConfigurationsOutcome.cs"
	"$ProvisoScriptRoot\enums\FacetProcessingState.cs"
	"$ProvisoScriptRoot\enums\RebaseOutcome.cs"
	"$ProvisoScriptRoot\enums\ValidationErrorType.cs"
	"$ProvisoScriptRoot\enums\ValidationsOutcome.cs"
	"$ProvisoScriptRoot\classes\models\Assertion.cs"
	"$ProvisoScriptRoot\classes\models\Definition.cs"
	"$ProvisoScriptRoot\classes\models\Rebase.cs"
	"$ProvisoScriptRoot\classes\models\Facet.cs"
	"$ProvisoScriptRoot\classes\models\FacetsCatalog.cs"
	"$ProvisoScriptRoot\classes\processing\AssertionResult.cs"
	"$ProvisoScriptRoot\classes\processing\ConfigurationError.cs"
	"$ProvisoScriptRoot\classes\processing\ConfigurationResult.cs"
	"$ProvisoScriptRoot\classes\processing\RebaseResult.cs"
	"$ProvisoScriptRoot\classes\processing\ValidationError.cs"
	"$ProvisoScriptRoot\classes\processing\ValidationResult.cs"
	"$ProvisoScriptRoot\classes\processing\FacetProcessingResult.cs"
	"$ProvisoScriptRoot\classes\DslStack.cs"
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

# 4. Import/Build Facets and dynamically create Verify|Configure-<FacetName> funcs. 
Clear-FacetProxies -RootDirectory $ProvisoScriptRoot;
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'facets/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$currentFacet = $script:ProvisoFacetsCatalog.GetFacetByFileName(($file.Basename));
		if ($null -ne $currentFacet) {
			$facetName = $currentFacet.Name;
			$allowsRebase = $currentFacet.RebasePresent;
			
			Export-FacetProxyFunction -RootDirectory $ProvisoScriptRoot -FacetName $facetName;
			Export-FacetProxyFunction -RootDirectory $ProvisoScriptRoot -FacetName $facetName -ExecuteConfiguration -AllowRebase:$allowsRebase;
		}
	}
	catch {
		throw "Unable to Import Facet: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 5. Import DSL Facet-Proxies (syntactic sugar):
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $ProvisoScriptRoot -ChildPath 'facets/generated/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$provisoPublicModuleMembers += $file.Basename;
	}
	catch {
		throw "Unable to Import Facet Proxy-Function: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 6. Export
Export-ModuleMember -Function $provisoPublicModuleMembers;
Export-ModuleMember -Alias * -Function *;