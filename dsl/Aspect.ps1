Set-StrictMode -Version 1.0;

function Aspect {
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$AspectBlock,
		[string]$Scope,
		[switch]$OrderDescending = $false,
		[string]$OrderByChildKey
	);
	
	Validate-SurfaceBlockUsage -BlockName "Aspect";
	$ExpectBlock = $null;  # Required as a declaration to allow the Expect{} func to set this (if it's defined/called/set)
	
	& $AspectBlock;
}