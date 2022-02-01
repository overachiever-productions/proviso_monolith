Set-StrictMode -Version 1.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;

	With \\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Execute {
		Validate-FirewallRules;
		Validate-ServerName;
		Validate-TestingSurface;
	};

	Summarize -All;

#>


function Execute {
	[Alias("Invoke")]
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$Directives,
		[Parameter(ValueFromPipeline)]
		[PSCustomObject]$Config
	);
	
	Validate-MethodUsage -MethodName "Execute";
	
	# Allow $Config to be provided from $global:PVConfig if it has been loaded previously... (and isn't EXPLICITLY provided via pipeline);
	# NOTE: this if-check/assignment works _FINE_ in the 'process' block. It fails MISERABLY in a 'begin' block - for reasons I can't quite figure out yet. 
	if ($null -eq $Config) {
		$Config = $global:PVConfig;
	
		if ($null -eq $Config) {
			throw "Missing -Config within Execute function. Cannot continue.";
		}
	}

	$global:PVExecuteActive = $true;
	
	& $Directives;
	
	$global:PVExecuteActive = $false;
}