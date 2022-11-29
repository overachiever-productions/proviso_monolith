﻿Set-StrictMode -Version 1.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Map -ProvisoRoot "\\storage\Lab\proviso\";
	Target -ConfigFile "\\storage\lab\proviso\definitions\PRO\PRO-197.psd1" -Strict:$false;

	#Validate-WindowsPreferences;

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
		[string]$NextRunbookOperation
	);
	
	begin {
		Validate-Config;
		Validate-MethodUsage -MethodName "Execute-Runbook";
		
		$runbook = $PVCatalog.GetRunbook($RunbookName);
		if ($null -eq $runbook) {
			throw "Invalid Runbook Name. Runbook [$RunbookName] does not exist or has not been loaded. If this is a custom Runbook, verify that [Import-Runbook] has been correctly executed.";
		}
		
		if ($runbook.RequiresDomainCreds) {
			if (-not ($PVDomainCreds.CredentialsSet)) {
				throw "Invalid Operation. Runbook [$($runbook.Name)] specifies that -DomainCredentials are required. Please use [Assign] to provide Domain Credentials using one of the parameters provided.";
			}
		}
		
		if ($runbook.RequiresDomainCredsConfigureOnly) {
			if ("Provision" -eq $Operation) {
				if (-not ($PVDomainCreds.CredentialsSet)) {
					throw "Invalid Operation. Runbook [$($runbook.Name)] specifies that -DomainCredentialsConfigOnly are required. Please use [Assign] to provide Domain Credentials using one of the parameters provided.";
				}
			}
		}
		
		if ($AllowReboot) {
			if ([string]::IsNullOrEmpty($NextRunbookOperation) -or ($runbook.DeferRebootUntilRunbookEnd)) {
				$PVContext.WriteLog("Bypassing requirement for Reboot Credentials as -AllowReboot will be for simple Restart (vs Restart + Resume).", "Debug");
			}
			else {
				if (-not ($PVDomainCreds.RebootCredentials)) {
					throw "Invalid Operation. In order to -AllowReboot, you must use Assign to either supply -PasswordForReboot or specify a -RebootCredential.";
				}
			}
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
			$PVContext.StartRunbookProcessing($runbook, $Operation, $AllowReboot, $AllowSqlRestart);
			
			$runbookBlock = $runbook.RunbookBlock;
			
			& $runbookBlock;
		}
		catch {
			$exceptionMessage = "Fatal Exception within Runbook [$($runbook.Name)]. Execution Terminated.`rEXCEPTION: $_  `r`t$($_.ScriptStackTrace) ";
			
			$PVContext.WriteLog($exceptionMessage, "Critical");
			throw $exceptionMessage;
		}
		finally {
			$PVContext.EndRunbookProcessing();
		}
		
		if (-not ($runbook.SkipSummary)) {
			# vNEXT: add this option/functionality:
			#Summarize -LastRunbook -ProblemsOnly:$($runbook.SummarizeProblemsOnly);
			Summarize -LatestRunbook;
		}
	};
	
	end {
		
		# Process DEFERRED Reboots:
		if ($PVContext.RebootRequired) {
			if ($AllowReboot -and ($runbook.DeferRebootUntilRunbookEnd)) {
				
				$waitSeconds = $runbook.WaitSecondsBeforeReboot;
				if ($NextRunbookOperation) {
					Restart-Server -RestartRunbookTarget $NextRunbookOperation -WaitSeconds $waitSeconds;
				}
				else {
					Restart-Server -WaitSeconds $waitSeconds;
				}
			}
			else {
				$PVContext.WriteLog("Runbook Execution Complete. REBOOT REQUIRED. $($PVContext.RebootReason)", "IMPORTANT");
			}
		}
			
		if ($NextRunbookOperation) {
			Write-Host "Found a 'next' runbook to process - called: $NextRunbookOperation ";
			
			# TODO: 
			#   split by - to get $operation and $runbookName. 
			# 	verify that $runbookName exists and is a valid runbook - i..e, via $PVCatalog... 
			#   run a simple call to Execute-Runbook (i.e., self) along the following-lines: 
			# 	Execute-Runbook -RunbookName $runbookName -Operation $operation -AllowReboot:$AllowReboot -AllowSqlRestart:$AllowSqlRestart;
		}
	};
}