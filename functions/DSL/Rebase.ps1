Set-StrictMode -Version 1.0;

function Rebase {
	param (
		[scriptblock]$RebaseBlock
	);
	
	Limit-ValidProvisoDSL -MethodName "Rebase" -AsFacet;
	
	$rebase = New-Object Proviso.Models.Rebase($RebaseBlock, $Name);
	$facet.AddRebase($rebase);
}