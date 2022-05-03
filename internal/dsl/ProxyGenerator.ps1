Set-StrictMode -Version 1.0;

filter Clear-ProvisoProxies {
	param (
		[Parameter(Mandatory)]
		[string]$RootDirectory
	);
	
	try {
		[string]$surfaceProxies = Join-Path -Path $RootDirectory -ChildPath "\generated\SurfaceProxies.ps1";
		[string]$runbookProxies = Join-Path -Path $RootDirectory -ChildPath "\generated\RunbookProxies.ps1";
		
		$template = 'Set-StrictMode -Version 1.0; ';
		
		Set-Content -Path $surfaceProxies -Value $template -Confirm:$false -Force; # NOTE: allowing newline... 
		Set-Content -Path $runbookProxies -Value $template -Confirm:$false -Force; # NOTE: allowing newline... 
	}
	catch {
		throw "Exception Clearing Proxies in [$RootDirectory]. `rException: $_ `r`t$($_.ScriptStackTrace)";
	}
}

filter Generate-SurfaceProxies {
	param (
		[Parameter(Mandatory)]
		[string]$RootDirectory,
		[Parameter(Mandatory)]
		[string]$SurfaceName,
		[switch]$AllowRebase
	);
	
	[string]$template = '
#-------------------------------------------------------------------------------------
# {0}
#-------------------------------------------------------------------------------------
function Validate-{0} {{
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "{0}" -Operation "Validate";
}}

function Configure-{0} {{{1}
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "{0}" -Operation "Configure"{2};
}}

function Run-{0} {{{1}
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "{0}" -Operation $operationType{2};
}}
';
	
	$rebase = $rebaseParamDef = "";
	if ($AllowRebase) {
		$rebase = " -ExecuteRebase:`$ExecuteRebase -Force:`$Force ";
		$rebaseParamDef = "`r`tparam(`r`t`t[switch]`$ExecuteRebase = `$false, `r`t`t[Switch]`$Force = `$false`r`t); ";
	}
	
	$body = [string]::Format($template, $SurfaceName, $rebaseParamDef, $rebase);
	
	try {
		$proxiesPath = Join-Path -Path $RootDirectory -ChildPath "\generated\SurfaceProxies.ps1";
		
		Add-Content -Path $proxiesPath -Value $body -NoNewline -Confirm:$false;
	}
	catch {
		throw "Error adding proxy definitions for Surface [$SurfaceName]`rEXCEPTION: $_  `r`t$($_.ScriptStackTrace) ";
	}
}

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