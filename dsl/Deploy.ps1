Set-StrictMode -Version 1.0;

function Deploy {
	param (
		[scriptblock]$DeployBlock
	);
	
	Validate-SurfaceBlockUsage -BlockName "Deploy";
	
	$deploy = New-Object Proviso.Models.Deploy($DeployBlock, $Name);
	$surface.AddDeploy($deploy);
}