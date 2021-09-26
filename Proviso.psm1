Set-StrictMode -Version 3.0;

[string[]]$provisoPublicModuleMembers = @();
[string]$script:provisoRoot = $PSScriptRoot;


# 1. Import (.NET) Classes


# 2. Build Public Functions / DSL
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $script:provisoRoot -ChildPath 'functions/*.ps1') -Recurse -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$provisoPublicModuleMembers += $file.Basename;
	}
	catch {
		throw "Unable to dot source Core Function: [$($file.FullName)]";
	}
}

# 3. Build Internal Functions + DSL Support
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $script:provisoRoot -ChildPath 'internal/*.ps1') -Recurse -ErrorAction Stop))) {
	try {
		. $file.FullName;
	}
	catch {
		throw "Unable to dot source Internal Function: [$($file.FullName)]";
	}
}

# 4. Import/Build Facets and dynamically create Verify|Configure-<FacetName> funcs. 
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $script:provisoRoot -ChildPath 'facets/*.ps1') -Recurse -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$provisoPublicModuleMembers += "Verify-$($file.Basename)";
		$provisoPublicModuleMembers += "Configure-$($file.Basename)";
	}
	catch {
		throw "Unable to dot source Facet: [$($file.FullName)]";
	}
}

# 5. Export
Export-ModuleMember -Function $provisoPublicModuleMembers;