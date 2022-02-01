Set-StrictMode -Version 1.0;

filter Clear-SurfaceProxies {
	param (
		[Parameter(Mandatory)]
		[string]$RootDirectory
	);
	
	try {
		[string]$proxypath = Join-Path -Path $RootDirectory -ChildPath "\surfaces\generated";
		[string]$targetPath = "$($proxypath)\*.ps1";
		
		Remove-Item -Path $targetPath -Recurse -Confirm:$false -Force;
	}
	catch {
		throw "Exception clearing Generated Surfaces in $targetPath. `rException: $_ `r`t$($_.ScriptStackTrace)";
	}
}