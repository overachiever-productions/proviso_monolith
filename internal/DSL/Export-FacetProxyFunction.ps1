Set-StrictMode -Version 1.0;

filter Export-FacetProxyFunction {
	
	param (
		[Parameter(Mandatory)]
		[string]$RootDirectory,
		[Parameter(Mandatory)]
		[string]$FacetName,
		[Parameter(Mandatory)]
		[ValidateSet("Validate", "Configure")]
		[string]$MethodType,
		[switch]$AllowRebase
	);
	
	[string]$template = 'Set-StrictMode -Version 1.0;

function {0}-{1} {{
	
	param (
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
		[PSCustomObject]$Config{2}
	);
	
	Limit-ValidProvisoDSL -MethodName "{0}";

	Process-Facet -FacetName "{1}" -Config $Config -{0}{3};
}}';
		
	
	$rebaseInput = "";
	$rebaseOutput = "";
	if ($AllowRebase) {
		$rebaseInput = ",`r`t`t[Switch]`$AllowRebase = `$false ";
		$rebaseOutput = " -AllowRebase:`$AllowRebase";
	}
	
	$body = [string]::Format($template, $MethodType, $FacetName, $rebaseInput, $rebaseOutput);
	
	try {
		$filePath = Join-Path -Path $RootDirectory -ChildPath "\facets\generated";
		$filePath = Join-Path -Path $filePath -ChildPath "$MethodType-$FacetName.ps1";
		
		Set-Content -Path $filePath -Value $body -NoNewline -Confirm:$false -Force;
	}
	catch {
		
	}
}

#Export-FacetProxyFunction -RootDirectory "D:\Dropbox\Repositories\proviso" -FacetName "ServerName" -MethodType Configure -AllowRebase;