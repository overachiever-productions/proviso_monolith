Set-StrictMode -Version 3.0;

[string]$script:ProvisoScriptRoot = $PSScriptRoot;

# 1. Import (.NET) classes (ordered to address dependency chains)
$classFiles = @(
	"$ProvisoScriptRoot\classes\DslStack.cs"
	"$ProvisoScriptRoot\classes\Assertion.cs"
	"$ProvisoScriptRoot\classes\RebaseOutcome.cs"
	"$ProvisoScriptRoot\classes\Rebase.cs"
	"$ProvisoScriptRoot\classes\Definition.cs"
	"$ProvisoScriptRoot\classes\TestOutcome.cs"
	"$ProvisoScriptRoot\classes\Facet.cs"
	"$ProvisoScriptRoot\classes\FacetManager.cs"
	"$ProvisoScriptRoot\classes\ProcessingContext.cs"
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
		
		$currentFacet = $script:provisoFacetManager.GetFacetByFileName(($file.Basename));
		if ($null -ne $currentFacet) {
			$facetName = $currentFacet.Name;
			$allowsRebase = $currentFacet.AllowsReset;
			
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