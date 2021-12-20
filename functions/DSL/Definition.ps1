﻿Set-StrictMode -Version 1.0;

function Definition {
	param (
		[Parameter(Mandatory, Position = 0, ParameterSetName = "named")]
		[string]$Description,
		$Expect,
		[switch]$ExpectCurrentKeyValue = $false,
		[string]$ExpectChildKey = $null,
		[Parameter(Mandatory, Position = 2, ParameterSetName = "named")]
		[ScriptBlock]$DefinitionBlock,
		[Alias("Has")]
		[Switch]$For,   # noise/syntactic-sugar doesn't DO anything... 
		[ValidateNotNullOrEmpty()]
		[string]$Key
	)
	
	begin {
		Validate-FacetBlockUsage -BlockName "Definition";
		
		if ($ExpectChildKey) {
			if ($defsType -ne [Proviso.Enums.DefinitionType]::Group) {
				throw "Invalid Argument. -ExpectChildKey can ONLY be used for [Definition] methods within [Group-Definitions] blocks";
			}
		}
		
		if ($ExpectCurrentKeyValue){
			if ($defsType -ne [Proviso.Enums.DefinitionType]::Value) {
				throw "Invalid Argument. -ExpectCurrentKeyValue can ONLY be specified for [Definition] methods within [Value-Definitions] blocks.";
			}
		}
		
		if ($defsType -eq [Proviso.Enums.DefinitionType]::Value) {
			if ($null -eq $ValueKey) {
				throw "Invalid Argument. Value-Definitions blocks MUST include the -ValueKey argument.";
			}			
		}
	}
	
	process {
		$definition = New-Object Proviso.Models.Definition($facet, $Description, $defsType);
		
		if (-not ([string]::IsNullOrEmpty($Key))) {
			
			$keyType = (Get-ProvisoConfigDefault -Key $Key -ValidateOnly);
			if ($null -eq $keyType) {
				throw "Invalid -Key value ([$($Key)]) specified for Definition [$Description] within Facet [$($facet.Name)].";
			}
			
			if ($keyType.GetType() -notin "bool", "string", "hashtable", "system.object[]") {
				throw "Invalid -Key.DataType for Key ([$($Key)]) specified for Definition [$Description] within Facet [$($facet.Name)]."
			}
			
			$definition.AddKeyAsExpect($Key);
		}
		
		if ($ExpectCurrentKeyValue) {
			$definition.UseCurrentValueKeyAsExpect($ValueKey);
		}
		
		if ($defsType -eq [Proviso.Enums.DefinitionType]::Value) {
			if (-not ($ExpectCurrentKeyValue)) {
				$definition.SetParentKeyForValueDefinition($ValueKey);
			}
		}
		
		if ($ExpectChildKey){
			$definition.SetParentKeyForValueDefinition($GroupKey);
			$definition.SetChildKeyForGroupDefinition($ExpectChildKey);
		}
		
		& $DefinitionBlock;
	}
	
	end {
		
		# -Expect is just 'syntactic sugar':
		if ($Expect -and ($null -eq $definition.Expectation)) {
			$script = "return '$Expect';";
			$ExpectBlock = [scriptblock]::Create($script);
			
			$definition.AddExpect($ExpectBlock);
		}
		
		$facet.AddDefinition($definition);
	}
}