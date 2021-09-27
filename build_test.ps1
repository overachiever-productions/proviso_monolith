Set-StrictMode -Version 3.0;

[string[]]$provisoPublicModuleMembers = @();
[string]$script:provisoRoot = $PSScriptRoot;

# 1. Import (.NET) classes (ordered to address dependency chains)
$classFiles = @(
	"$PSScriptRoot\classes\AssertionOutcome.cs"
	"$PSScriptRoot\classes\Assertion.cs"
	"$PSScriptRoot\classes\Rebase.cs"
	"$PSScriptRoot\classes\Definition.cs"
	"$PSScriptRoot\classes\TestOutcome.cs"
	"$PSScriptRoot\classes\Facet.cs"
	"$PSScriptRoot\classes\FacetManager.cs"
);
Add-Type -Path $classFiles;

#$facetManager = [Proviso.Models.FacetManager]::GetInstance();
#Write-Host $facetManager.GetStuff();
#
#return;
#$block = {
#	Write-Host "this is a nested code block";
#	$x = 12;
#}
#
#$assertion = New-Object Proviso.Models.Assertion("my assertion", "Facet Name Here",  $block);
#Write-Host "Assertion.Name: $($assertion.Name) ";
#Write-Host "Assertion.ScriptBlock $($assertion.ScriptBlock) ";
#
#$outcome = New-Object Proviso.Models.AssertionOutcome($true, $null);
#$assertion.AssignOutcome($outcome);
#
#Write-Host "Assertion.Outcome: $($assertion.Outcome.Passed)";
#return;

# 2. Build Public Functions / DSL
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
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $script:provisoRoot -ChildPath 'facets/*.ps1') -Recurse -ErrorAction Stop))) {
	try {
		. $file.FullName;
		
		$validateFacet = {
			param (
				[Parameter(Mandatory)]
				[string]$FacetName,
				[Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
				[PSCustomObject]$Config
			);
			
			Process-Facet -FacetName $FacetName -Config $Config -Validate;
		};
		
		$configureFacet = {
			param (
				[Parameter(Mandatory)]
				[string]$FacetName,
				[Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
				[PSCustomObject]$Config
			);
			
			Process-Facet -FacetName $FacetName -Config $Config -Configure;
		};
		
		$validateName = "Validate-$($file.Basename)";
		$configureName = "Configure-$($file.Basename)";
		
		Set-Item -Path "Function:$validateName" -Value $validateFacet;
		Set-Item -Path "Function:$configureName" -Value $configureFacet;
		
		$provisoPublicModuleMembers += $validateName;
		$provisoPublicModuleMembers += $configureName;
	}
	catch {
		throw "Unable to Import Facet: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

$facetManager = [Proviso.Models.FacetManager]::GetInstance();


Write-Host "`r-------------------------------------------------------------------------------------------";
Write-Host "FacetManager.Count: $($facetManager.Count)";
Write-Host "Count of Required-Packages Assertions: $($facetManager.GetFacet('RequiredPackages').Assertions.Count) ";

# 5
#Get-ChildItem -Path Function:;
#$provisoPublicModuleMembers;
#Export-ModuleMember -Function $script:provisoPublicModuleMembers;
