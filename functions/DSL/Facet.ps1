Set-StrictMode -Version 1.0;

function Facet {
	param (
		[Parameter(Mandatory, Position = 0, ParameterSetName = "named")]
		[string]$Description,
		$Expect,
		$ConfiguredBy,
		[Parameter(Mandatory, Position = 2, ParameterSetName = "named")]
		[ScriptBlock]$FacetBlock,
		[string]$CompoundValueKey = $null,  		# basically the same as the -ValueKey ... but has to be implemented per Facet (instead of 'up' at Facets-block level).
		[string]$ExpectKeyValue = $null,
		[switch]$ExpectValueForCurrentKey = $false,
		[string]$ExpectValueForChildKey = $null,
		[switch]$ExpectValueForCompoundKey = $false,
		[Alias("Has")]
		[switch]$For,   # noise/syntactic-sugar doesn't DO anything... 
		[switch]$RequiresReboot = $false,
		[switch]$IgnoreOnEmptyConfig = $false,
		[ValidateNotNullOrEmpty()]
		[string]$Key
	)
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Facet";
		switch ($facetType) {
			Simple {
				if ($ExpectValueForCurrentKey) {
					throw "Invalid Argument. -ExpectValueForCurrentKey can ONLY be used with [Facet] methods in [Group-Facets] and [Value-Facets] blocks. Use -ExpectKey instead.";
				}
				
				if ($ExpectValueForChildKey) {
					throw "Invalid Argument. -ExpectValueForChildKey can ONLY be used for [Facet] methods within [Group-Facets] blocks";
				}
				
				if ($ExpectValueForCompoundKey) {
					throw "Invalid Argument. -ExpectValueForCompoundKey can ONLY be used for [Facet] methods within [Compound-Facets] blocks";
				}
				
				if ($OrderByChildKey) {
					throw "Invalid Argument. -OrderByChildKey can ONLY be specified for [Facet] methods within [Group-Facets] blocks.";
				}
				
				if ($ValueKey) {
					throw "Invalid Argument -ValueKey can ONLY be specified for [Facet] methods within [Value-Facets] blocks.";
				}
				
				if ($GroupKey) {
					throw "Invalid Argument. -GroupKey can ONLY be specified for [Facet] methods within [Group-Facets] blocks.";
				}
				
				if ($CompoundValueKey) {
					throw "Invalid Argument. -CompoundValueKey can ONLY be specified for [Facet] methods within [Compound-Facets] blocks.";
				}
				
				if ($OrderDescending) {
					throw "Invalid Argument. -OrderDescending can ONLY be used for [Facet] methods within [Value-Facets] blocks.";
				}
				
				if ($ExpectKeyValue) {
					$keyType = (Get-ProvisoConfigDefault -Key $ExpectKeyValue -ValidateOnly);
					if ($null -eq $keyType) {
						throw "Invalid -ExpectKeyValuevalue ([$($ExpectKeyValue)]) specified for Facet [$Description] within Surface [$($surface.Name)].";
					}
					
					if ($keyType.GetType() -notin "bool", "string", "hashtable", "system.object[]") {
						throw "Invalid -ExpectKeyValue.DataType for Key ([$($ExpectKeyValue)]) specified for Facet [$Description] within Surface [$($surface.Name)]."
					}
				}
			}
			Value {
				if ($ExpectKeyValue) {
					throw "Invalid Argument. -ExpectKeyValue can NOT be used in [Group-Facets] or [Value-Facets] blocks - it can only be used in [Facets] blocks.";
				}
				
				if ($ExpectValueForChildKey) {
					throw "Invalid Argument. -ExpectValueForChildKey can ONLY be used for [Facet] methods within [Group-Facets] blocks";
				}
								
				if ($ExpectValueForCompoundKey) {
					throw "Invalid Argument. -ExpectValueForCompoundKey can ONLY be used for [Facet] methods within [Compound-Facets] blocks";
				}
				
				if ($OrderByChildKey) {
					throw "Invalid Argument. -OrderByChildKey can ONLY be specified for [Facet] methods within [Group-Facets] and [Compound-Facets] blocks.";
				}

				if ($GroupKey) {
					throw "Invalid Argument. -GroupKey can ONLY be specified for [Facet] methods within [Group-Facets] and [Compound-Facets] blocks.";
				}
				
				if ($CompoundValueKey) {
					throw "Invalid Argument. -CompoundValueKey can ONLY be specified for [Facet] methods within [Compound-Facets] blocks.";
				}
				
				if ($null -eq $ValueKey) {
					throw "Invalid Argument. [Value-Facets] blocks MUST include the -ValueKey argument.";
				}
			}
			Group {
				if ($ExpectKeyValue) {
					throw "Invalid Argument. -ExpectKeyValue can NOT be used in [Group-Facets] or [Value-Facets] blocks - it can only be used in [Facets] blocks.";
				}
				
				if ($ValueKey) {
					throw "Invalid Argument. -ValueKey can ONLY be specified for [Facet] methods within [Value-Facets] blocks.";
				}
				
				if ($CompoundValueKey) {
					throw "Invalid Argument. -CompoundValueKey can ONLY be specified for [Facet] methods within [Compound-Facets] blocks.";
				}
				
				if ($OrderDescending) {
					throw "Invalid Argument. -OrderDescending can ONLY be used for [Facet] methods within [Value-Facets] and [Compound-Facets] blocks.";
				}
				
				if ($null -eq $GroupKey) {
					throw "Invalid Argument. [Group-Facets] blocks MUST include the -GroupKey argument.";
				}
				
				if ($ExpectValueForChildKey) {
					if ($Expect) {
						throw "Invalid Argument. -ExpectValueForChildKey and the -Expect argument can NOT both be used - use one or the other.";
					}
					
					if ($ExpectBlock) {
						throw "Invalid Argument. -ExpectValueForChildKey and an explicit [Expect] block can NOT both be used - use one or the other.";
					}
					
					if ($ExpectValueForCurrentKey) {
						throw "Invalid Argument. -ExpectValueForChildKey and -ExpectValueForCurrentKey can NOT both be used - use one or the other.";
					}
				}
				
				if ($ExpectValueForCompoundKey) {
					throw "Invalid Argument. -ExpectValueForCompoundKey can ONLY be used for [Facet] methods within [Compound-Facets] blocks";
				}
			}
			Compound {
				if ($ExpectKeyValue) {
					throw "Invalid Argument. -ExpectKeyValue can NOT be used in [Group-Facets] or [Value-Facets] blocks - it can only be used in [Facets] blocks.";
				}
				
				if ($ValueKey) {
					throw "Invalid Argument -ValueKey can ONLY be specified for [Facet] methods within [Value-Facets] blocks.";
				}
				
				if ($null -eq $GroupKey) {
					throw "Invalid Argument. [Group-Facets] blocks MUST include the -GroupKey and -ValueKey arguments.";
				}
				
				if ($null -eq $CompoundValueKey) {
					throw "Invalid Argument. [Compound-Facets] blocks MUST include the -GroupKey and -CompoundValueKey arguments.";
				}
				
				if ($ExpectValueForChildKey) {
					throw "Invalid Argument. -ExpectValueForChildKey can ONLY be used for [Facet] methods within [Group-Facets] blocks";
				}
				
				if ($ExpectValueForCompoundKey) {
					if ($Expect) {
						throw "Invalid Argument. -ExpectValueForCompoundKey and the -Expect argument can NOT both be used - use one or the other.";
					}
					
					if ($ExpectBlock) {
						throw "Invalid Argument. -ExpectValueForCompoundKey and an explicit [Expect] block can NOT both be used - use one or the other.";
					}
					
					if ($ExpectValueForCurrentKey) {
						throw "Invalid Argument. -ExpectValueForCompoundKey and -ExpectValueForCurrentKey can NOT both be used - use one or the other.";
					}
				}
			}
			default {
				throw "Proviso Framework Exception. Unable to validate Facet of type [$facetType].";
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
				throw "Invalid -Key value ([$($Key)]) specified for Facet [$Description] within Surface [$($surface.Name)].";
			}
			
			if ($keyType.GetType() -notin "bool", "string", "hashtable", "system.object[]") {
				throw "Invalid -Key.DataType for Key ([$($Key)]) specified for Facet [$Description] within Surface [$($surface.Name)]."
			}
		}
	}
	
	process {
		$facet = New-Object Proviso.Models.Facet($surface, $Description, $facetType);
			
		if ($RequiresReboot) {
			$facet.SetRequiresReboot();
		}
		
		if ($Key) {
			$facet.SetStaticKey($Key);
		}
		
		switch ($facet.FacetType) {
			Simple {
				if ($ExpectKeyValue) {
					$facet.SetStaticKey($ExpectKeyValue)
					$facet.SetExpectAsStaticKeyValue();
				}
			}
			Value {
				$facet.SetIterationKeyForValueAndGroupFacets($ValueKey);
				
				if ($ExpectValueForCurrentKey) {
					$facet.SetExpectAsCurrentIterationKeyValue();
				}
				
				if ($OrderDescending) {
					$facet.AddOrderDescending();
				}
			}
			Group {
				$facet.SetIterationKeyForValueAndGroupFacets($GroupKey);
				
				if ($ExpectValueForCurrentKey) {
					$facet.SetExpectAsCurrentIterationKeyValue();
				}
				
				if ($ExpectValueForChildKey) {
					$facet.SetExpectAsCurrentChildKeyValue($ExpectValueForChildKey);
				}
				
				if ($OrderByChildKey) {
					$facet.AddOrderByChildKey($OrderByChildKey);
				}
			}
			Compound {
				$facet.SetIterationKeyForValueAndGroupFacets($GroupKey);
				$facet.SetCompoundIterationValueKey($CompoundValueKey);
				
				if ($ExpectValueForCurrentKey) {
					$facet.SetExpectAsCurrentIterationKeyValue();
				}
				
				if ($ExpectValueForCompoundKey) {
					$facet.SetExpectAsCompoundKeyValue();
				}
				
				if ($OrderByChildKey) {
					$facet.AddOrderByChildKey($OrderByChildKey);
				}
			}
		}
		
		& $FacetBlock;
	}
	
	end {
		# -Expect is just 'syntactic sugar':
		if ($Expect -and ($null -eq $facet.Expectation)) {
			$script = "return '$Expect';";
			$ExpectBlock = [scriptblock]::Create($script);
			
			$facet.SetExpect($ExpectBlock);
		}
		
		if ($ConfiguredBy -and ($null -eq $facet.Configure)) {
			$surface.VerifyConfiguredBy($Description, $ConfiguredBy);	# throws if the name isn't valid (i.e., found (already) within the current surface)
			$facet.SetConfiguredBy($ConfiguredBy);
		}
		
		$surface.AddFacet($facet);
	}
}