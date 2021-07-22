Set-StrictMode -Version 1.0;

function Find-SqlSetupExe {
	param (
		[Parameter(Mandatory = $true)]
		[string]$RootDirectory,
		[Parameter(Mandatory = $true)]
		[string]$SetupKey
	);
	
	
 	# Allow for hard-coded paths as the 'key' - i.e., overrides of convention can be specified... (e.g., Z:\setup.exe, etc.)
	if (Test-Path -Path $SetupKey) {
		return $SetupKey;
	}
	
	[string]$path = Join-Path -Path $RootDirectory -ChildPath $SetupKey -AdditionalChildPath "setup.exe";
	if (Test-Path -Path $path) {
		return $path;
	}
	
	return $null;
}