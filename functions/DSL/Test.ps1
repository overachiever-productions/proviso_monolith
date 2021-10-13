Set-StrictMode -Version 1.0;

function Test {
	param (
		[ScriptBlock]$TestBlock
	);
	
	Limit-ValidProvisoDSL -MethodName "Test" -AsFacet;
	$definition.AddTest($TestBlock);
}