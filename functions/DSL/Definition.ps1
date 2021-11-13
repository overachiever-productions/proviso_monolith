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
		[Switch]$For,   # noise/syntactic-sugar doesn't DO anything... 
		[ValidateNotNullOrEmpty()]
		$Key
	)
	
	begin {
		Limit-ValidProvisoDSL -MethodName "Definition" -AsFacet;
		$definition = New-Object Proviso.Models.Definition($Description);
		
		if (-not([string]::IsNullOrEmpty($Key))) {
			
			$keyType = (Get-ProvisoConfigDefault -Key $Key -ValidateOnly);
			if ($null -eq $keyType) {
				throw "Invalid -Key value ([$($Key)]) specified for Definition [$Description] within Facet [$($facet.Name)].";
			}
			
			if ($keyType.GetType() -notin "bool", "string", "hashtable", "system.object[]") {
				throw "Invalid -Key.DataType for Key ([$($Key)]) specified for Definition [$Description] within Facet [$($facet.Name)]."
			}
			
			$definition.AddKey($Key);
		}
	}
	
	process {
		& $DefinitionBlock;
	}
	
	end {
		$facet.AddDefinition($definition);
	}
}