Set-StrictMode -Version 1.0;

function Rebase {
	param (
		[scriptblock]$RebaseBlock
	);
	
	Validate-FacetBlockUsage -BlockName "Rebase";
	
	$rebase = New-Object Proviso.Models.Rebase($RebaseBlock, $Name);
	$facet.AddRebase($rebase);
}