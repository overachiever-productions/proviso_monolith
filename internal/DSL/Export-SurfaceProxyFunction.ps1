Set-StrictMode -Version 1.0;

filter Export-SurfaceProxyFunction {
	
	param (
		[Parameter(Mandatory)]
		[string]$RootDirectory,
		[Parameter(Mandatory)]
		[string]$SurfaceName,
		[switch]$Configure = $false,
		[switch]$AllowRebase
	);
	
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