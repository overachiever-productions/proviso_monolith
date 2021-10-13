Set-StrictMode -Version 1.0;

function Definitions {
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Definitions
	);
	
	Limit-ValidProvisoDSL -MethodName "Definitions" -AsFacet;
	
	& $Definitions;
}