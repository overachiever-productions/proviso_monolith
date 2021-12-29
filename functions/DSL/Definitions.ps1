Set-StrictMode -Version 1.0;

function Definitions {
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Definitions
	);
	
	Validate-FacetBlockUsage -BlockName "Definitions";
	$defsType = [Proviso.Enums.DefinitionType]::Simple;
	$OrderByChildKey = $null;
	
	& $Definitions;
}

function Value-Definitions {
	[Alias("KeyValue-Definitions")]
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Definitions,
		[Parameter(Mandatory)]
		[string]$ValueKey
	);
	
	Validate-FacetBlockUsage -BlockName "Value-Definitions";
	$defsType = [Proviso.Enums.DefinitionType]::Value;
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
		# REFACTOR: this needs to be called: -OrderConfigurationGroupsByChildKey			YEAH. that's a MOUTH-FUL. BUT. each definition will also have a -Priority or -OrderBy value itself... 
		[string]$OrderByChildKey
	);
	
	Validate-FacetBlockUsage -BlockName "Group-Definitions";
	$defsType = [Proviso.Enums.DefinitionType]::Group;
	
	& $Definitions;
}