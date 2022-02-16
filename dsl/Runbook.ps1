Set-StrictMode -Version 1.0;

<#
	SCOPE:
		- Wrapper for 1 or more Surfaces (along with other custom logic that might make sense)... 
		- Primarily an orchestrator - i.e., do THIS, then THIS, then THAT, etc... 

		- Specific Runbooks simply keep the list of Surfaces to process. 
		- At runtime, Runbooks are handled by the Execute-Runbook (internal) function. 
		- Execute-Runbook, in turn, is called by either: 
				> Evaluate-<RunbookName>
				> Provision-<RunbookName>
				> Document-<RunbbookName>
			and will do the requisite processing as needed... 


		- Execute-Runbook can also manage the notion of a 'NextRunbook' to process after successful completion of the current Surface. 
		- Likewise, Execute-Runbook will pass along an -AllowReboot switch (passed in from user/caller/scripts) that can be reviewed INSIDE of specific Runbook implementations.

	vNEXT:
		It _MIGHT_ make sense to have 3x phases of execution within a runbook, something equivalent to: 
			Prep (Open?), Run, Close - i.e., funcs/blocks that allow things like validation (Prep) and spin-up of resources (Prep), handle main execution, and .. do anything needed 'after'. 
			Only, while I can think of how something like this MIGHT make sense, I can't honestly think of any specific cases where I'd use and... 
			as such, it's just a COMPLICATION at this point. i.e., going MVP with a single 'main' body/func at this point, but can/could expand this later IF needed. 



	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Assign -ProvisoRoot "\\storage\Lab\proviso\";
	Target "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1";

	Evaluate-Tests;

#>

function Runbook {
	
	param (
		[Parameter(Position = 0, ParameterSetName = "default", Mandatory)]
		[string]$Name,
		[Parameter(Mandatory, Position = 1, ParameterSetName = "default")]
		[ScriptBlock]$RunbookBlock,
		[switch]$RequiresDomainCredentials = $false,
		[ValidateSet("5Seconds", "10Seconds", "30Seconds", "60Seconds", "90Seconds")]
		[string]$WaitBeforeRebootFor,
		[switch]$DeferRebootUntilRunbookEnd = $false,
		[switch]$SkipSummary = $false,
		[switch]$SummarizeProblemsOnly = $false
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Runbook";
		
		if ($SkipSummary -and $SummarizeProblemsOnly) {
			throw "Invalid Arguments. -SkipSummary and -SummarizeProblemsOnly are mutually exclusive and can NOT both be selected - use one, the other, or neither.";
		}
		
		$runbookFileName = Split-Path -Path $MyInvocation.ScriptName -LeafBase;
		if ($null -eq $Name) {
			$Name = $runbookFileName;
		}
		
		$runbook = New-Object Proviso.Models.Runbook($Name, $runbookFileName, ($MyInvocation.ScriptName).Replace($ProvisoScriptRoot, ".."));
	};
	
	process {
		$runbook.AddScriptBlock($RunbookBlock);
		$runbook.SetOptions($RequiresDomainCredentials, $DeferRebootUntilRunbookEnd, $SkipSummary, $SummarizeProblemsOnly, $WaitBeforeRebootFor);
	};
	
	end {
		$global:PVCatalog.AddRunbook($runbook);
	};
}