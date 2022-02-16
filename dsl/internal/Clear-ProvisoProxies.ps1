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