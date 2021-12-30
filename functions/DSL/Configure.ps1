Set-StrictMode -Version 1.0;

function Configure {
	param (
		[ScriptBlock]$ConfigureBlock
	);
	
	Validate-FacetBlockUsage -BlockName "Configure";
	
	$definition.SetConfigure($ConfigureBlock)
}