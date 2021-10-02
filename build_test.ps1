Set-StrictMode -Version 3.0;

[string[]]$provisoPublicModuleMembers = @();
[string]$script:provisoRoot = $PSScriptRoot;

# 1. Import (.NET) classes (ordered to address dependency chains)
$classFiles = @(
	"$PSScriptRoot\classes\DslStack.cs"
	"$PSScriptRoot\classes\Assertion.cs"
	"$PSScriptRoot\classes\RebaseOutcome.cs"
	"$PSScriptRoot\classes\Rebase.cs"
	"$PSScriptRoot\classes\Definition.cs"
	"$PSScriptRoot\classes\TestOutcome.cs"
	"$PSScriptRoot\classes\Facet.cs"
	"$PSScriptRoot\classes\FacetManager.cs"
);
Add-Type -Path $classFiles; # damn i love powershell... 

# 2. Build Public Functions / DSL
$script:provisoDslStack = [Proviso.Models.DslStack]::Instance;
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $script:provisoRoot -ChildPath 'functions/*.ps1') -Recurse -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$provisoPublicModuleMembers += $file.Basename;
	}
	catch {
		throw "Unable to dot source Core Function: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 3. Build Internal Functions + DSL Support
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $script:provisoRoot -ChildPath 'internal/*.ps1') -Recurse -ErrorAction Stop))) {
	try {
		. $file.FullName;
	}
	catch {
		throw "Unable to dot source Internal Function: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 4. Import/Build Facets and dynamically create Verify|Configure-<FacetName> funcs. 
$script:provisoFacetManager = [Proviso.Models.FacetManager]::Instance;
Clear-FacetProxies -RootDirectory $script:provisoRoot;
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $script:provisoRoot -ChildPath 'facets/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$currentFacet = $script:provisoFacetManager.GetFacetByFileName(($file.Basename));
		if ($null -ne $currentFacet) {
			$facetName = $currentFacet.Name;
			$allowsRebase = $currentFacet.AllowsReset;
			
			Export-FacetProxyFunction -RootDirectory $script:provisoRoot -FacetName $facetName -MethodType Validate;
			Export-FacetProxyFunction -RootDirectory $script:provisoRoot -FacetName $facetName -MethodType Configure -AllowRebase:$allowsRebase;
		}
	}
	catch {
		throw "Unable to Import Facet: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 5. Import DSL Facet-Proxies (syntactic sugar):
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $script:provisoRoot -ChildPath 'facets/generated/*.ps1') -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$provisoPublicModuleMembers += $file.Basename;
	}
	catch {
		throw "Unable to Import Facet Proxy-Function: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 6. Export
$provisoPublicModuleMembers;
#Export-ModuleMember -Function $script:provisoPublicModuleMembers;
