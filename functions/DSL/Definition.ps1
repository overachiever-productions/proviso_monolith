Set-StrictMode -Version 1.0;

function Definition {
	param (
		[Parameter(Mandatory, Position = 0, ParameterSetName = "named")]
		[string]$Description,
		[string]$Expect,
		# optional mechanism for handing in Expect details...
		[Parameter(Mandatory, Position = 2, ParameterSetName = "named")]
		[ScriptBlock]$DefinitionBlock,
		[Alias("Has")]
		[Switch]$For   # noise/syntactic-sugar doesn't DO anything... 
	)
	
	begin {
		Limit-ValidProvisoDSL -MethodName "Definition" -AsFacet;
		$definition = New-Object Proviso.Models.Definition($Description);
	}
	
	process {
		& $DefinitionBlock;
	}
	
	end {
		$facet.AddDefinition($definition);
	}
}