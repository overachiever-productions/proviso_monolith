Set-StrictMode -Version 1.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Assign -ProvisoRoot "\\storage\Lab\proviso\";
	Target "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1";

	Evaluate-Tests;

#>


function Execute-Runbook {
	param (
		[Parameter(Mandatory)]
		[string]$RunbookName,
		[Parameter(Mandatory)]
		[ValidateSet("Evaluate", "Provision", "Document")]
		[string]$Operation,
		[switch]$AllowReboot = $false,
		[switch]$AllowSqlRestart = $false, 
		[string]$NextRunbookName,
		[switch]$SkipSummary = $false,
		[switch]$SummarizeProblemsOnly = $false
	);
	
	begin {
		Validate-Config;
		Validate-MethodUsage -MethodName "Execute-Runbook";
		
		if ($SkipSummary -and $SummarizeProblemsOnly) {
			throw "Invalid Arguments. -SkipSummary and -SummarizeProblemsOnly are mutually exclusive and can NOT both be selected - use one, the other, or neither.";
		}
		
		$runbook = $PVCatalog.GetRunbook($RunbookName);
		if ($null -eq $runbook) {
			throw "Invalid Runbook Name. Runbook [$RunbookName] does not exist or has not been loaded. If this is a custom Runbook, verify that [Import-Runbook] has been correctly executed.";
		}
	};
	
	process {
		# NOTE: a Runbook primarily contains CALLS to Execute various Surfaces - one after another. 
		#  		Surfaces SHOULD have sufficient error-handling during processing to AVOID throwing exceptions up/out to a wrapper like the Runbook that's calling them.
		# 		BUT, while that's true, one of the BIG benefits of a Runbook is that failure to process things correctly in, say, Step 2 of 8 steps, will TERMINATE
		# 			processing - instead of something in step 2 crashing/burning, which likely means that steps 3, 4, 5, 6, 7, and 8 are either 'doomed from the start'
		# 			or VERY likely to throw additional errors/problems. 
		# 		Or, in other words: a benefit of Runbooks is they increase error handling and allow for EARLIER interception of problems... 
		try {
			$PVContext.StartRunbookProcessing($runbook, $Operation);
			
			$runbookBlock = $runbook.RunbookBlock;
			
			& $runbookBlock;
		}
		catch {
			# TODO: how do I surface this? i THINK i just let it throw right on 'out' - i.e., up to the caller/console/etc. 
			#   	but, it MIGHT make sense to also add this into the $PVContext as a .AddFatalRunbookException() - or something similar IF ... callers (Summarize?) were to need to show this. 
			# 			but, yeah, i think this just throws 'all the way up' and terminates processing - it SHOULD... (unless I can think of reasons not to)
			$exceptionMessage = "Fatal Exception within Runbook [$($runbook.Name)]. Execution Terminated.`rEXCEPTION: $_  `r`t$($_.ScriptStackTrace) ";
			
			$PVContext.WriteLog($exceptionMessage, "Critical");
			throw $exceptionMessage;
		}
		finally {
			$PVContext.EndRunbookProcessing();
		}
		
		if (-not ($SkipSummary)){
			#Summarize -LastRunbook -ProblemsOnly:$SummarizeProblemsOnly;
			Summarize -All;
		}
	};
	
	end {
				
		# now that we're done... if there's a $NextRunbook ... run that... 
	};
}