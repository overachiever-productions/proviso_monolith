﻿Set-StrictMode -Version 1.0;

# TODO: Refactor this and Generate-SurfaceProxies down/into a single file called ProxyGenerator - or something similar.

filter Generate-RunbookProxies {
	param (
		[Parameter(Mandatory)]
		[string]$RootDirectory,
		[Parameter(Mandatory)]
		[string]$RunbookName
	);
	
	# TODO: add Document-<RunbookName>
	[string]$template = '
#-------------------------------------------------------------------------------------
# {0}
#-------------------------------------------------------------------------------------
function Evaluate-{0} {{
	Validate-MethodUsage -MethodName "Evaluate";
	Execute-Runbook -RunbookName "{0}" -Operation Evaluate;
}}

function Provision-{0} {{
	param(
		[switch]$AllowReboot = $false, 
		[switch]$AllowSqlRestart = $false, 
		[string]$NextRunbookOperation = $null
	);

	Validate-MethodUsage -MethodName "Provision";
	Execute-Runbook -RunbookName "{0}" -Operation Provision -AllowReboot:$AllowReboot -AllowSqlRestart:$AllowSqlRestart -NextRunbookOperation $NextRunbookOperation;
}}															 
';
	$body = [string]::Format($template, $RunbookName);
	
	try {
		$proxiesPath = Join-Path -Path $RootDirectory -ChildPath "\generated\RunbookProxies.ps1";
		
		Add-Content -Path $proxiesPath -Value $body -NoNewline -Confirm:$false;
	}
	catch {
		throw "Error adding proxy definitions for Runbook [$RunbookName]`rEXCEPTION: $_  `r`t$($_.ScriptStackTrace) ";
	}
}