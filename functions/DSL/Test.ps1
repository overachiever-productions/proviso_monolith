Set-StrictMode -Version 1.0;

function Test {
	param (
		[ScriptBlock]$TestBlock
	);
	
	Validate-FacetBlockUsage -BlockName "Test";
	
	$definition.AddTest($TestBlock);
}