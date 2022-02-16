Set-StrictMode -Version 1.0;

function Rebase {
	param (
		[scriptblock]$RebaseBlock
	);
	
	Validate-SurfaceBlockUsage -BlockName "Rebase";
	
	$rebase = New-Object Proviso.Models.Rebase($RebaseBlock, $Name);
	$surface.AddRebase($rebase);
}