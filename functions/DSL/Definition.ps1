Set-StrictMode -Version 1.0;

function Definition {
	param (
		[Parameter(Mandatory, Position = 0, ParameterSetName = "named")]
		[string]$Description,
		$Expect,
		[Parameter(Mandatory, Position = 2, ParameterSetName = "named")]
		[ScriptBlock]$DefinitionBlock,
		[string]$ExpectKeyValue = $null,
		[switch]$ExpectValueForCurrentKey = $false, 
		[string]$ExpectValueForChildKey = $null,
		[Alias("Has")]
		[switch]$For,   # noise/syntactic-sugar doesn't DO anything... 
		[switch]$RequiresReboot = $false,
		[ValidateNotNullOrEmpty()]
		[string]$Key
	)
	
	begin {
		Validate-FacetBlockUsage -BlockName "Definition";
		switch ($definitionType) {
			Simple {
				if ($ExpectValueForCurrentKey) {
					throw "Invalid Argument. -ExpectValueForCurrentKey can ONLY be used with [Definition] methods in [Group-Definitions] and [Value-Definitions] blocks. Use -ExpectKey instead.";
				}
				
				if ($ExpectValueForChildKey) {
					throw "Invalid Argument. -ExpectValueForChildKey can ONLY be used for [Definition] methods within [Group-Definitions] blocks";
				}
				
				if ($OrderByChildKey) {
					throw "Invalid Argument. -OrderByChildKey can ONLY be specified for [Definition] methods within [Group-Definitions] blocks.";
				}
				
				if ($ValueKey) {
					throw "Invalid Argument -ValueKey can ONLY be specified for [Definition] methods within [Value-Definitions] blocks.";
				}
				
				if ($GroupKey) {
					throw "Invalid Argument. -GroupKey can ONLY be specified for [Definition] methods within [Group-Definitions] blocks.";
				}
				
				if ($OrderDescending) {
					throw "Invalid Argument. -OrderDescending can ONLY be used for [Definition] methods within [Value-Definitions] blocks.";
				}
				
				if ($ExpectKeyValue) {
					$keyType = (Get-ProvisoConfigDefault -Key $ExpectKeyValue -ValidateOnly);
					if ($null -eq $keyType) {
						throw "Invalid -ExpectKeyValuevalue ([$($ExpectKeyValue)]) specified for Definition [$Description] within Facet [$($facet.Name)].";
					}
					
					if ($keyType.GetType() -notin "bool", "string", "hashtable", "system.object[]") {
						throw "Invalid -ExpectKeyValue.DataType for Key ([$($ExpectKeyValue)]) specified for Definition [$Description] within Facet [$($facet.Name)]."
					}
				}
			}
			Value {
				if ($ExpectKeyValue) {
					throw "Invalid Argument. -ExpectKeyValue can NOT be used in [Group-Definitions] or [Value-Definitions] blocks - it can only be used in [Definitions] blocks.";
				}
				
				if ($ExpectValueForChildKey) {
					throw "Invalid Argument. -ExpectValueForChildKey can ONLY be used for [Definition] methods within [Group-Definitions] blocks";
				}
				
				if ($OrderByChildKey) {
					throw "Invalid Argument. -OrderByChildKey can ONLY be specified for [Definition] methods within [Group-Definitions] blocks.";
				}

				if ($GroupKey) {
					throw "Invalid Argument. -GroupKey can ONLY be specified for [Definition] methods within [Group-Definitions] blocks.";
				}
				
				if ($null -eq $ValueKey) {
					throw "Invalid Argument. [Value-Definition] blocks MUST include the -ValueKey argument.";
				}
			}
			Group {
				if ($ExpectKeyValue) {
					throw "Invalid Argument. -ExpectKeyValue can NOT be used in [Group-Definitions] or [Value-Definitions] blocks - it can only be used in [Definitions] blocks.";
				}
				
				if ($ValueKey) {
					throw "Invalid Argument. -ValueKey can ONLY be specified for [Definition] methods within [Value-Definition] blocks.";
				}

				if ($OrderDescending) {
					throw "Invalid Argument. -OrderDescending can ONLY be used for [Definition] methods within [Value-Definition] blocks.";
				}
				
				if ($null -eq $GroupKey) {
					throw "Invalid Argument. [Group-Definition] blocks MUST include the -GroupKey argument.";
				}
				
				if ($ExpectValueForChildKey) {
					if ($Expect) {
						throw "Invalid Argument. -ExpectValueForChildKey and xxx can NOT both be used - use one or the other.";
					}
					
					if ($ExpectBlock) {
						throw "Invalid Argument. -ExpectValueForChildKey and an explicit [Expect] block can NOT both be used - use one or the other.";
					}
					
					if ($ExpectValueForCurrentKey) {
						throw "Invalid Argument. -ExpectValueForChildKey and -ExpectValueForCurrentKey can NOT both be used - use one or the other.";
					}
				}
			}
			default {
				throw "Proviso Framework Exception. Unable to validate Definition of type [$definitionType].";
			}
		}
		
		if ($ExpectValueForCurrentKey) {
			if ($ExpectKeyValue) {
				throw "Invalid Argument. -ExpectValueForCurrentKey and -ExpectKeyValue can NOT both be used - use one or the other.";
			}
			
			if ($ExpectValueForChildKey) {
				throw "Invalid Argument. -ExpectValueForCurrentKey and -ExpectValueForChildKey can NOT both be used - use one or the other.";
			}
			
			if ($Expect) {
				throw "Invalid Argument. -ExpectValueForCurrentKey can NOT be used with the -Expect switch - use one or the other.";
			}
			
			if ($ExpectBlock) {
				throw "Invalid Argument. -ExpectValueForCurrentKey can NOT be used with an explicit [Expect] block - use one or the other.";
			}
		}
		
		if ($ExpectBlock) {
			if ($Expect) {
				throw "Invalid Argument. -Expect can NOT be used with an explicit [Expect] block - use one or the other.";
			}
			
			if ($ExpectKeyValue){
				throw "Invalid Argument. -ExpectKeyValue can NOT be used with an explicit [Expect] block - use one or the other.";
			}
			
			if ($ExpectValueForChildKey) {
				throw "Invalid Argument. -ExpectValueForChildKey can NOT be used with an explicit [Expect] block - use one or the other.";
			}
		}
		
		if ($Key){
			$keyType = (Get-ProvisoConfigDefault -Key $Key -ValidateOnly);
			if ($null -eq $keyType) {
				throw "Invalid -Key value ([$($Key)]) specified for Definition [$Description] within Facet [$($facet.Name)].";
			}
			
			if ($keyType.GetType() -notin "bool", "string", "hashtable", "system.object[]") {
				throw "Invalid -Key.DataType for Key ([$($Key)]) specified for Definition [$Description] within Facet [$($facet.Name)]."
			}
		}
	}
	
	process {
		$definition = New-Object Proviso.Models.Definition($facet, $Description, $definitionType);
			
		if ($RequiresReboot) {
			$definition.SetRequiresReboot();
		}
		
		if ($Key) {
			$definition.SetStaticKey($Key);
		}
		
		switch ($definition.DefinitionType) {
			Simple {
				if ($ExpectKeyValue) {
					$definition.SetStaticKey($ExpectKeyValue)
					$definition.SetExpectAsStaticKeyValue();
				}
			}
			Value {
				$definition.SetIterationKeyForValueAndGroupDefinitions($ValueKey);
				
				if ($ExpectValueForCurrentKey) {
					$definition.SetExpectAsCurrentIterationKeyValue();
				}
				
				if ($OrderDescending) {
					$definition.AddOrderDescending();
				}
			}
			Group {
				$definition.SetIterationKeyForValueAndGroupDefinitions($GroupKey);
				
				if ($ExpectValueForCurrentKey) {
					$definition.SetExpectAsCurrentIterationKeyValue();
				}
				
				if ($ExpectValueForChildKey) {
					$definition.SetExpectAsCurrentChildKeyValue($ExpectValueForChildKey);
				}
				
				if ($OrderByChildKey) {
					$definition.AddOrderByChildKey($OrderByChildKey);
				}
			}
		}
		
		& $DefinitionBlock;
	}
	
	end {
		# -Expect is just 'syntactic sugar':
		if ($Expect -and ($null -eq $definition.Expectation)) {
			$script = "return '$Expect';";
			$ExpectBlock = [scriptblock]::Create($script);
			
			$definition.SetExpect($ExpectBlock);
		}
		
		$facet.AddDefinition($definition);
	}
}