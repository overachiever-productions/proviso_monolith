Set-StrictMode -Version 1.0;

function Definitions {
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Definitions
	);
	
	Validate-FacetBlockUsage -BlockName "Definitions";
	$definitionType = [Proviso.Enums.DefinitionType]::Simple;
	$ValueKey = $null;
	$GroupKey = $null;
	$CompoundValueKey = $null;
	$ExpectBlock = $null;
	$OrderByChildKey = $null;
	$OrderDescending = $false;
	
	& $Definitions;
}

function Value-Definitions {
	[Alias("KeyValue-Definitions")]
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Definitions,
		[Parameter(Mandatory)]
		[string]$ValueKey,
		[switch]$OrderDescending = $false
	);
	
	Validate-FacetBlockUsage -BlockName "Value-Definitions";
	$definitionType = [Proviso.Enums.DefinitionType]::Value;
	$GroupKey = $null;
	$CompoundValueKey = $null;
	$ExpectBlock = $null;
	$OrderByChildKey = $null;
	
	& $Definitions;
}

function Group-Definitions {
	[Alias("KeyGroup-Definitions")]
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Definitions,
		[Parameter(Mandatory)]
		[string]$GroupKey,
		[string]$OrderByChildKey
	);
	
	Validate-FacetBlockUsage -BlockName "Group-Definitions";
	$definitionType = [Proviso.Enums.DefinitionType]::Group;
	$ValueKey = $null;
	$CompoundValueKey = $null;
	$ExpectBlock = $null;
	$OrderDescending = $false;
	
	& $Definitions;
}

function Compound-Definitions {
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Definitions,
		[Parameter(Mandatory)]
		[string]$GroupKey,
		
# DOH... yeah - this is implmemented in the CHILD func (Definition) - not here... 
#		[Parameter(Mandatory)]
#		[string]$CompoundValueKey,
		[string]$OrderByChildKey,
		[switch]$OrderDescending = $false
	)
	
	Validate-FacetBlockUsage -BlockName "Compound-Definitions";
	$definitionType = [Proviso.Enums.DefinitionType]::Compound;
	$ValueKey = $null;
	$ExpectBlock = $null;
	
	& $Definitions;
}