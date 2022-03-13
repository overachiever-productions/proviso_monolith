Set-StrictMode -Version 1.0;

function Facet {
	param (
		[Parameter(Mandatory, Position = 0, ParameterSetName = "named")]
		[string]$Name,
		$Expect,
		[switch]$UsesBuild = $false,
		[Parameter(Mandatory, Position = 2, ParameterSetName = "named")]
		[ScriptBlock]$FacetBlock,
		[string]$For = "",
		[string]$ExpectKeyValue = $null, 				# expect a single, specific, key. e.g., -ExpectKeyValue "Host.FirewallRules.EnableICMP"
		[switch]$ExpectCurrentKeyValue =  $false, 		# expect the current key value for Value or Group Keys e.g., if the key is "Host.LocalAdministrators", 'expect' an entry for each key-value. Whereas, if the key is "AdminDb.*", expect a value/key for each SQL Server instance (MSSQLSERVER, X3, etc.)
		[string]$ExpectChildKeyValue = $null,			# e.g., -ExpectChildKeyValue "Enabled" would return the key for, say, AdminDb.RestoreTestJobs..... Enabled (i.e., parent/iterator + current child-key)
		[string]$IterationKey,							# e.g., if the -Scope is "ExpectedDirectories.*", then -IterationKey could be "RawDirectories" or "VirtualSqlServerServiceAccessibleDirectories"
		[switch]$ExpectIterationKeyValue = $false,		# e.g., if we're working through an -IterationKey of "RawDirectories" (for a -Scope of "ExpectedDirectories"), then we'd Expect one entry/value her for each 'Raw Directory' (or path) defined in the config
		[switch]$RequiresReboot = $false
	)
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Facet";
		
		$facetType = [Proviso.Enums.FacetType]::Simple;
		if ($Scope) {
			$trimmedScopeKey = $Scope -replace ".\*", "";
			
			if (-not (Is-ValidProvisoKey -Key $trimmedScopeKey)) {
				throw "Fatal Error. Aspect Scope for Facet [$Name] within Surface [$($surface.Name)] is invalid. Key [$Scope] is not valid.";
			}
			
			$keyType = Get-KeyType $trimmedScopeKey;
			
			switch ($keyType) {
				"Static" {
				}
				"Dynamic" {
					$facetType = [Proviso.Enums.FacetType]::Value;
				}
				"SqlInstance" {
					$facetType = [Proviso.Enums.FacetType]::Group;
				}
				"Complex" {
					$facetType = [Proviso.Enums.FacetType]::Compound;
				}
				default {
					throw
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
		
		Write-Host "$($surface.Name).$Name -> $facetType ";
	}
	
	process {
		$facet = New-Object Proviso.Models.Facet($surface, $Name, $facetType);
		
		if ($RequiresReboot) {
			$facet.SetRequiresReboot();
		}
		
		if ($ExpectKeyValue) {
			$facet.SetStaticKey($ExpectKeyValue);
			$facet.SetExpectAsStaticKeyValue(); # TODO: see if there's any reason to NOT combine these 2x calls down/into a single operation... 
		}
		
		switch ($facet.FacetType) {
			Simple {
			}
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
		
		if ($UsesBuild -and ($null -eq $facet.Configure)) {
			#$surface.VerifyCanUseBuild(); # throws if there aren't BUILD/DEPLOY funcs. 
			$facet.SetUsesBuild();
		}
		
		$surface.AddFacet($facet);
	}
}