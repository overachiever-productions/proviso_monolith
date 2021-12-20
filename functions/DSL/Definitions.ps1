Set-StrictMode -Version 1.0;

function Definitions {
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Definitions
	);
	
	Validate-FacetBlockUsage -BlockName "Definitions";
	$defsType = [Proviso.Enums.DefinitionType]::Simple;
	
	& $Definitions;
}

<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	
	#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-FirewallRules;
	#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Configure-ServerName; # -ExecuteRebase -Force;
	#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-RequiredPackages;

	With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-LocalAdministrators;
	#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-TestingFacet;
	With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-DataCollectorSets;

	Summarize -All -IncludeAllValidations; # -IncludeAssertions;

#>

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
	
	& $Definitions;
}

# THESE NOTES USED TO BE In the LocalAdministrators Facet:
# 		Finally... the above gets me that much closer to being able to handle things like: 
# 			ExpectedShares - they're just a TINY bit more complex than "for N admins" - as in, they're multiple properties/values per each 'loop' or iteration. 
# 		  ExpectedDirectories - ditto with the above. 
# 		  EthernetAdapters - again, just multiple-ish properties. 
# 		 	  ... then, getting more complex:
# 		 	ExpectedDisks ... yeah, these are COMPLEX AF... but, 'each' is just a 'rule'... with a) lots of properties and b) COMPLEX state. 
# 		    ... finally: 
# 			SQL Installs, SQL Configs, and anything else that can/will be scoped by an {INSTANCE}
# 				basically, they're just 'really complex disks or nics' in terms of complexity and scope/state. 
# 					moreover, if i 'write' the code for MSSQLSERVER as an 'option' (plugable variable or whatever)
# 					then... the ONLY thing that'd change for, say, a named instance... would be the name and so on... 
  		


function Group-Definitions {
	[Alias("KeyGroup-Definitions")]
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Definitions,
		[Parameter(Mandatory)]
		[string]$GroupKey
	);
	
	Validate-FacetBlockUsage -BlockName "Group-Definitions";
	$defsType = [Proviso.Enums.DefinitionType]::Group;
	
	& $Definitions;
}