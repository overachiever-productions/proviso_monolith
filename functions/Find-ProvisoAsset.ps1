Set-StrictMode -Version 1.0;

function Find-ProvisoAsset {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$ProvisoRoot,
		[string]$Asset,
		[string[]]$AllowedExtensions,
		[switch]$PartialMatches = $false,
		[switch]$CorrectCase = $true
	);
	
	if (-not (Test-Path -Path $ProvisoRoot)){
		throw "Invalid Proviso Root specified: $ProvisoRoot";
	}
	
	$matchedPath = $null;
	
	# Asset may be an absolute path - in which case it's an override - and we're done:
	if (Test-Path -Path $Asset -ErrorAction SilentlyContinue) {
		$matchedPath = $Asset;
	}
	
	if ($matchedPath -eq $null) {
		
		foreach ($ext in $AllowedExtensions) {
			if (-not ($ext.StartsWith("."))) {
				$ext = ".$($ext)";
			}
			
			$testPath = Join-Path -Path $ProvisoRoot -ChildPath "\assets\$($Asset)$($ext)";
			if (Test-Path -Path $testPath) {
				$matchedPath = $testPath;
				break;
			}
		}
		
		if ($PartialMatches) {
			$testPath = Join-Path -Path $ProvisoRoot -ChildPath "\assets\";
			$matches = Get-ChildItem -Path $testPath -Filter "*$($Asset)*";
			
			if ($matches.Count -eq 1) {
				$matchedPath = $matches[0].FullName;
			}
			if ($matches.Count -gt 1) {
				throw "Error. Attempt to use -PartialMatches for Asset $Asset against assets directory resulted in > 1 potential pattern match. Terminating...";
			}
		}
	}
	
	if ($matchedPath -ne $null) {
		if ($CorrectCase) {
			$parent = Split-Path -Path $matchedPath;
			$child = Split-Path -Path $matchedPath -Leaf;
			
			$object = Get-ChildItem -Path $parent -Filter $child;
			return $object.FullName;
		}
		else {
			return $Asset;
		}
	}
}