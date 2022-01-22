Set-StrictMode -Version 1.0;

<#

	So... the overall approach to how I'm addressing RunBooks (e.g., take a look at the 2x-ish ROUGH examples in the /runbooks folder)... 
		is looking great. 
		
	WITH ONE BIG EXCEPTION:
		It's dumb to have a facet for, say, "Configure"-AdminDb with a bunch of static calls to Provision-XyzFacet. 
			As in, I LIKE the ability to control the order of operations - i.e., which facet should be processed first and so on... 
			that's the whole point of a runbook - an ordered set of facet-processors. 

		the DUMB part is ... what IF I don't want to PROVISION something and, instead, want to 'just' validate? 
			(or, later on, what if I don't want to 'validate' or provision - and 'just' want to document?)

			So... I THINK what I need to do is wire up runbooks to, instead (of calling validate or provision) ... call Process-<FacetNameHere>. 
			and the parent object (the RunBook) can be allowed as a LEGIT caller ... i.e., only allow Process-XXXXFacetName via DSL semantics IF we're in a runbook... 
					(or something like that). 

			I COULD, also, create some sort of 'alias' like Run-<FacetName> or Execute-<FacetName> or even Process-<FacetName>
				which would 'route' each one of these into a call against Process-Facet ... where the -Provision(swithc) would be handled ... by means of whehter the
				run book was doing a validate, provision, or document operation... 


	Some verbs that might work for the above: 
		
		PROCESS-xxx	
			pretty sure this one makes the most sense... 

		apply / employ
		implement
		enforce
		run (yeah... kinda weak-sauce but... then again, maybe not?)
		operate
		engage/employ
		
		render (hmmmm)
			yield... 

		handle-xxx (weak-sauce, but it works)

#>

function Runbook {
	
	param (
		[Parameter(Mandatory)]
		[Alias("For")]
		[string]$Name,
		[switch]$AllowReboot = $false,
		[string]$NextRunbook,
		[PSCustomObject]$Config
	);
	
	begin {
		
	};
	
	process {
		
	};
	
	end {
		
	};
}