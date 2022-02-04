Set-StrictMode -Version 1.0;

function Build {
	param (
		[scriptblock]$BuildBlock
	);
	
	Validate-SurfaceBlockUsage -BlockName "Build";
	
	$build = New-Object Proviso.Models.Build($BuildBlock, $Name);
	$surface.AddBuild($build);
}