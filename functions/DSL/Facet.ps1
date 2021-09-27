Set-StrictMode -Version 1.0;

<# 
	SCOPE: 
		A facet IS NOT a true function. 
		It's a container for ordered script-blocks. 
			It provides a hierarchical means of defining what blocks of code should be allocated/assigned to various PROCESSING tasks
			when working through VALIDATING and/or CONFIGURING a given Facet. 


	FUNCTIONALITY: 
		When a 'Facet' is run/imported, it doesn't 'DO' anything. 
			Instead, whenever a Facet is run/imported, it creates a xxx - which is a list of ordered code-blocks that are executed by... 
				xxxx instead via Verify-<FacetName> and Configure-<FacetName> funcs... 

#>

function Facet {
	
	param (
		[Parameter(Mandatory, Position = 0, ParameterSetName = "default")]
		[string]$Name,
		[Parameter(Mandatory, Position = 1, ParameterSetName = "default")]
		[ScriptBlock]$Scripts,
		[switch]$AllowReset = $false
	);
	
	begin {
		$facetModel = New-Object Proviso.Models.Facet($Name, ($MyInvocation.ScriptName).Replace($script:provisoRoot, ".."));
	}
	
	process {
		
		function Assertions {
			param (
				[ScriptBlock]$Assertions
			);
			
			function Assert {
				param (
					[Parameter(Position = 0)]
					[string]$Description,
					[Parameter(Position = 1)]
					[ScriptBlock]$Assertion
				);
				
				$assertionModel = New-Object Proviso.Models.Assertion($Description, $Name, $Assertion);
				$facetModel.AddAssertion($assertionModel);
			}
			
			& $Assertions;
		}
		
		function Rebase {
			param (
				[scriptblock]$RebaseBlock
			);
			
			#$rebaseModel = New-Object Proviso.Models.Rebase()
		}
		
		function Definitions {
			param (
				[Parameter(Mandatory)]
				[ScriptBlock]$Definitions
			);
			
			function Definition {
				param (
					[Parameter(Mandatory, Position = 0, ParameterSetName = "named")]
					[string]$Description,
					[string]$Expect, 	# optional mechanism for handing in Expect details...
					[Parameter(Mandatory, Position = 2, ParameterSetName = "named")]
					[ScriptBlock]$Definition
				)
				
				function Expect {
					param (
						[ScriptBlock]$ExpectBlock
					);
				}
				
				function Test {
					param (
						[ScriptBlock]$TestBlock
					);
				}
				
				function Provision {
					param (
						[ScriptBlock]$ProvisionBlock
					);
				}
				
				
				Write-Host "`t`t`tIn an Actual Definition. Name: $Description ";
			}
			
			& $Definitions;
		}
		
		& $Scripts;
	}
	
	end {
		
		Write-Host "Adding Facet: $($facetModel.Name) to Manager...";
		[Proviso.Models.FacetManager]::GetInstance().AddFacet($facetModel);
	}
}

# --------------------------------------------------------------------------------------------------------------------------------------------------------
#  sample facet/dev-testing.... 
#
#Facet "NetworkAdapters" {
#	
#	Assertions {
#		Assert -Description "1. Something Should be Present." {
#			$stringHere = "this is where the actual assertion code would go. ";
#		}
#		Assert -Description "2. Another thing should be here." {
#			$stringHere = "this is where the actual assertion code would go. ";
#		}
#		Assert -Description "3. Third thing to do goes here... " {
#			if ($Config.GetValue("Host.Something.AnotherThing.Value")) {
#				throw "This won't get thrown until the actual assert is executed - assuming that -Config is an object at that point... ";
#			}
#		}
#	}
#	
#	Rebase {
#		$variable = "12345 - fake code block here.";
#	}
#	
#	Definitions {
#		Definition "IP Address" -Expect "192.168.1.200" {
#			Test {
#				$t = "do whatever it takes to get the current IP addy.";
#			}
#			Provision {
#				$p = "do whatever it takes to set the IP for such and such adapter to such and such IP. ";
#			}
#		}
#		Definition "IP Gateway" {
#			
#			Expect {
#				$Config.GetValue("Host.Definitions.VMNetwork.Gateway");
#			}
#			
#			Test {
#				$t = "get the IP gateway... ";
#			}
#			
#			Provision {
#				$p = "set the gateway for such and such adapter to expected/etc.";
#			}
#			
#		}
#		Definition "DNS Server Addresses" {
#			
#		}
#	}
#}