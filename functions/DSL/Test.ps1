Set-StrictMode -Version 1.0;

function Test {
	param (
		[ScriptBlock]$TestBlock
	);
	
	Validate-SurfaceBlockUsage -BlockName "Test";
	
	$definition.SetTest($TestBlock);
}