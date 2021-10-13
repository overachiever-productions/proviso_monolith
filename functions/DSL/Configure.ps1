Set-StrictMode -Version 1.0;

function Configure {
	param (
		[ScriptBlock]$ConfigureBlock
	);
	
	Limit-ValidProvisoDSL -MethodName "Configure" -AsFacet;
	$definition.AddConfiguration($ConfigureBlock)
}