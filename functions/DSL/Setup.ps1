Set-StrictMode -Version 1.0;

function Setup {
	param (
		[scriptblock]$SetupBlock
	);
	
	Validate-FacetBlockUsage -BlockName "Setup";
	
	$setup = New-Object Proviso.Models.Setup($SetupBlock, $Name);
	$facet.AddSetup($setup);
}