Set-StrictMode -Version 1.0;

filter Export-FacetProxyFunction {
	
	param (
		[Parameter(Mandatory)]
		[string]$RootDirectory,
		[Parameter(Mandatory)]
		[string]$FacetName,
		[switch]$ExecuteConfiguration = $false,
		[switch]$AllowRebase
	);
	
	# NOTE: $script:PVRunbookActive may NOT end up being used... 
	[string]$template = 'Set-StrictMode -Version 1.0;

function {0}-{1} {{
	
	param (
		[Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
		[PSCustomObject]$Config{2}
	);
	
	Validate-MethodUsage -MethodName "{0}";

	if(($global:PVExecuteActive -eq $true) -or ($global:PVRunBookActive -eq $true)) {{
		if($null -eq $Config) {{
			$Config = $global:PVConfig;
		}}
	}}

	Process-Facet -FacetName "{1}" -Config $Config {3}{4};
}}';
		
	
	$rebaseParamDef = "";
	$rebaseOutput = "";
	$executeConfig = "";
	if ($ExecuteConfiguration) {
		$executeConfig = "-ExecuteConfiguration";
		
		if ($AllowRebase) {
			$rebaseParamDef = ",`r`t`t[Switch]`$ExecuteRebase = `$false, `r`t`t[Switch]`$Force = `$false ";
			$rebaseOutput = "-ExecuteRebase:`$ExecuteRebase -Force:`$Force ";
		}
	}
	
	$methodType = "Validate";
	if ($ExecuteConfiguration) {
		$methodType = "Configure";
	}
	
	$body = [string]::Format($template, $methodType, $FacetName, $rebaseParamDef, $rebaseOutput, $executeConfig);
	
	try {
		$filePath = Join-Path -Path $RootDirectory -ChildPath "\facets\generated";
		$filePath = Join-Path -Path $filePath -ChildPath "$MethodType-$FacetName.ps1";
		
		Set-Content -Path $filePath -Value $body -NoNewline -Confirm:$false -Force;
	}
	catch {
		
	}
}

#Export-FacetProxyFunction -RootDirectory "D:\Dropbox\Repositories\proviso" -FacetName "ServerName";
#Export-FacetProxyFunction -RootDirectory "D:\Dropbox\Repositories\proviso" -FacetName "ServerName" -ExecuteConfiguration -AllowRebase;