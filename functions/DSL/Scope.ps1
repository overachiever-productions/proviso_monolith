Set-StrictMode -Version 1.0;

function Scope {
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Scope
	);
	
	Validate-SurfaceBlockUsage -BlockName "Scope";
	$facetType = [Proviso.Enums.FacetType]::Simple;
	$ValueKey = $null;
	$GroupKey = $null;
	$CompoundValueKey = $null;
	$ExpectBlock = $null;
	$OrderByChildKey = $null;
	$OrderDescending = $false;
	
	& $Scope;
}

function Value-Scope {
	[Alias("KeyValue-Scope")]
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Scope,
		[Parameter(Mandatory)]
		[string]$ValueKey,
		[switch]$OrderDescending = $false
	);
	
	Validate-SurfaceBlockUsage -BlockName "Value-Scope";
	$facetType = [Proviso.Enums.FacetType]::Value;
	$GroupKey = $null;
	$CompoundValueKey = $null;
	$ExpectBlock = $null;
	$OrderByChildKey = $null;
	
	& $Scope;
}

function Group-Scope {
	[Alias("KeyGroup-Scope")]
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Scope,
		[Parameter(Mandatory)]
		[string]$GroupKey,
		[string]$OrderByChildKey
	);
	
	Validate-SurfaceBlockUsage -BlockName "Group-Scope";
	$facetType = [Proviso.Enums.FacetType]::Group;
	$ValueKey = $null;
	$CompoundValueKey = $null;
	$ExpectBlock = $null;
	$OrderDescending = $false;
	
	& $Scope;
}

function Compound-Scope {
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Scope,
		[Parameter(Mandatory)]
		[string]$GroupKey,
		
# DOH... yeah - this is implmemented in the CHILD func (Facet) - not here... 
#		[Parameter(Mandatory)]
#		[string]$CompoundValueKey,
		[string]$OrderByChildKey,
		[switch]$OrderDescending = $false
	)
	
	Validate-SurfaceBlockUsage -BlockName "Compound-Scope";
	$facetType = [Proviso.Enums.FacetType]::Compound;
	$ValueKey = $null;
	$ExpectBlock = $null;
	
	& $Scope;
}