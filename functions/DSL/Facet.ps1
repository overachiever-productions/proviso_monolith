Set-StrictMode -Version 1.0;

function Facet {
	param (
		[Parameter(Mandatory, Position = 0, ParameterSetName = "named")]
		[string]$Description,
		$Expect,
		$ConfiguredBy,
		[Parameter(Mandatory, Position = 2, ParameterSetName = "named")]
		[ScriptBlock]$FacetBlock,
		[string]$For = "",
		[string]$ExpectKeyValue = $null, 			# expect a single, specific, key. e.g., -ExpectKeyValue "Host.FirewallRules.EnableICMP"
		[switch]$ExpectCurrentKeyValue = $false,   	# expect the current key value for Value or Group Keys e.g., if the key is "Host.LocalAdministrators", 'expect' an entry for each key-value. Whereas, if the key is "AdminDb.*", expect a value/key for each SQL Server instance (MSSQLSERVER, X3, etc.)
		[string]$ExpectChildKeyValue = $null,		# e.g., -ExpectChildKeyValue "Enabled" would return the key for, say, AdminDb.RestoreTestJobs..... Enabled (i.e., parent/iterator + current child-key)
		[string]$IterationKey, 						# e.g., if the -Scope is "ExpectedDirectories.*", then -IterationKey could be "RawDirectories" or "VirtualSqlServerServiceAccessibleDirectories"
		[switch]$ExpectIterationKeyValue = $false,  # e.g., if we're working through an -IterationKey of "RawDirectories" (for a -Scope of "ExpectedDirectories"), then we'd Expect one entry/value her for each 'Raw Directory' (or path) defined in the config
		[switch]$RequiresReboot = $false
	)
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Facet";
		
		$facetType = [Proviso.Enums.FacetType]::Simple;
		if ($Scope) {
			$trimmedScopeKey = $Scope -replace ".\*", "";
			$keyType = Get-ProvisoConfigDefault -Key $trimmedScopeKey -ValidateOnly;
			
			if ($null -eq $keyType) {
				throw "Invalid -Scope value ([$($Scope)]) specified for Facet [$Description] within Surface [$($surface.Name)].";
			}
			
			switch ($keyType.GetType()) {
				"bool" {
				}
				"string" {
				}
				{ "hashtable" -or "System.Collections.Hashtable" } {
					if ($IterationKey) {
						$facetType = [Proviso.Enums.FacetType]::Compound;
					}
					else {
						$facetType = [Proviso.Enums.FacetType]::Group;
					}
				}
				"system.object[]" {
					$facetType = [Proviso.Enums.FacetType]::Value;
				}
				default {
					throw "Invalid DataType for -Scope ([$($Scope)]) specified for Facet [$Description] within Surface [$($surface.Name)].";
				}
			}
		}
		
		# additional, per type, validations:
		switch ($facetType) {
			Simple {
				# OrderBy operations can only be set by specific facet types: 
				if ($OrderByChildKey -or $OrderDescending) {
					throw "Aspects may NOT specify an -OrderByChildKey or -OrderDescending directive unless they specify -Scope arguments for configuration keys to evaluate.";
				}
			}
			Value {
				
			}
			Group {
				
			}
			Compound {
				
			}
		}
	}
	
	process {
		$facet = New-Object Proviso.Models.Facet($surface, $Description, $facetType);
		
		if ($RequiresReboot) {
			$facet.SetRequiresReboot();
		}
		
		if ($ExpectKeyValue) {
			$facet.SetStaticKey($ExpectKeyValue);
			$facet.SetExpectAsStaticKeyValue();  # TODO: see if there's any reason to NOT combine these 2x calls down/into a single operation... 
		}
		
		switch ($facet.FacetType) {
			Simple {}
			Value {
				$facet.SetIterationKeyForValueAndGroupFacets($Scope);
				
				if ($ExpectCurrentKeyValue) {
					$facet.SetExpectAsCurrentIterationKeyValue();
				}
				
				if ($OrderDescending) {
					$facet.AddOrderDescending();
				}
			}
			Group {
				$facet.SetIterationKeyForValueAndGroupFacets($Scope);
				
				if ($ExpectCurrentKeyValue) {
					$facet.SetExpectAsCurrentIterationKeyValue();
				}

				if ($ExpectChildKeyValue) {
					$facet.SetExpectAsCurrentChildKeyValue($ExpectChildKeyValue);
				}
				
				if ($OrderByChildKey) {
					$facet.AddOrderByChildKey($OrderByChildKey);
				}
			}
			Compound {
				$facet.SetIterationKeyForValueAndGroupFacets($Scope);
				$facet.SetCompoundIterationValueKey($IterationKey);
				
				if ($ExpectCurrentKeyValue) {
					$facet.SetExpectAsCurrentIterationKeyValue();
				}
				
				if ($ExpectIterationKeyValue) {
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