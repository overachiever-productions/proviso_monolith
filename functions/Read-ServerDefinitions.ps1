Set-StrictMode -Version 3.0;

function Read-ServerDefinitions {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Path,
		[switch]$Strict = $true
	)
	
	if (!(Test-Path -Path $Path)) {
		throw "Invalid -Path value specified. The file $Path does NOT exist.";
	}
	$data = Import-PowerShellDataFile $Path;
	
	$output = [PSCustomObject]$data;
	
	$currentHostName = $env:COMPUTERNAME;
	
	if ($Strict) {
		if ($currentHostName -ne $output.TargetServer) {
			throw "HostName defined by $Path [$($output.TargetServer)] does NOT match current server hostname [$currentHostName]. Processing Aborted."
		}
	}
	
	return $output;
}