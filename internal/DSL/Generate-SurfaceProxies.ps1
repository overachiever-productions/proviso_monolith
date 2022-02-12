Set-StrictMode -Version 1.0;

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
	Process-Surface -SurfaceName "{0}";
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

<# 

	# NOTE: $script:PVRunbookActive may NOT end up being used... 
	[string]$template = 'Set-StrictMode -Version 1.0;

function {0}-{1} {{
	
	Validate-MethodUsage -MethodName "{0}";

	Process-Surface -SurfaceName "{1}" {3}{4};
}}';
		
	
	$rebaseParamDef = "";
	$rebaseOutput = "";
	$configureDirective = "";
	if ($Configure) {
		$configureDirective = "-Configure";
		
		if ($AllowRebase) {
			$rebaseParamDef = ",`r`t`t[Switch]`$ExecuteRebase = `$false, `r`t`t[Switch]`$Force = `$false ";
			$rebaseOutput = "-ExecuteRebase:`$ExecuteRebase -Force:`$Force ";
		}
	}
	
	$methodType = "Validate";
	if ($Configure) {
		$methodType = "Configure";
	}
	
	$body = [string]::Format($template, $methodType, $SurfaceName, $rebaseParamDef, $rebaseOutput, $configureDirective);
	
	try {
		$filePath = Join-Path -Path $RootDirectory -ChildPath "\surfaces\generated";
		$filePath = Join-Path -Path $filePath -ChildPath "$methodType-$SurfaceName.ps1";
		
		Set-Content -Path $filePath -Value $body -NoNewline -Confirm:$false -Force;
	}
	catch {
		
	}
}


#>