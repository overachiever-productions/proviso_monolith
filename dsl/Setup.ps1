Set-StrictMode -Version 1.0;

function Setup {
	param (
		[scriptblock]$SetupBlock
	);
	
	Validate-SurfaceBlockUsage -BlockName "Setup";
	
	$setup = New-Object Proviso.Models.Setup($SetupBlock, $Name);
	$surface.AddSetup($setup);
}