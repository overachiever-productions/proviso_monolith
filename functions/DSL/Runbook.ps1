Set-StrictMode -Version 1.0;

<#

	Like a Surface, a Runbook is an object with a few BLOCKS of code inside. 
		Unlike a Surface it's not NEARLY as complex - i.e., it'll basically just have either: 
			a. One block of functions or... 
			b. MIGHT be broken up into a couple of functions like: 
					- Assess/Setup/Stage/Prepare
						(validation and any other similar things... )
					- Main/Run?
						(i.e., the main block of code).
					- Reporting/Post-Processing/Disband/Dissolve/Resolve/CONCLUDE/Terminate
						(where we handle stuff like ... reporting, reboots, and the likes)



					- Before, During, After? 


		Otherwise, it, like a Surface will have a single 'processor' or main-func that runs the Runbook, called: 
			- Execute-Runbook
			
			And there will be 3x main facades for interacting with Execute-Runbook (i.e., Execute-Runbook should NOT be called directly, it'll be Internal). 
				> Evaluate-<RunbookName>
				> Provision-<RunbookName>
				> Document-<RunbbookName>


#>

function Runbook {
	
	param (
		[Parameter(Position = 0, ParameterSetName = "default", Mandatory)]
		[Alias("For")]
		[string]$Name,
		[Parameter(Mandatory, Position = 1, ParameterSetName = "default")]
		[ScriptBlock]$Scripts,
		[switch]$AllowReboot = $false,
		[string]$NextRunbook
		
		# Presumably... $PVConfig is what we'll expect to use in here? i.e., just need to figure out how to implement that 
		#  		based, effectively, on the same way that Surfaces are currently doing this... 
		#[PSCustomObject]$Config
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Runbook";
		
		
		
		
		# TODO: wire-up a new RunBook CLR object... 
	};
	
	process {
		
		& $Scripts;
	};
	
	end {
		# TODO: right now this object doesn't exist (ProvisoCatalog). There's a ProvisoCatalog... 
		# 		so, just repurpose that to serve for Surfaces, Runbooks, and anything else that makes sense along the line? 
		# 			ah... it should also keep track of Machines (configs at the specified location in \\ProvisoRoot\config\whatever or whatever... )
		$ProvisoCatalog.AddRunbook($runbook);
	};
}