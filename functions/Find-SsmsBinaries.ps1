Set-StrictMode -Version 1.0;

function Find-SsmsBinaries {
	param (
		[Parameter(Mandatory = $true)]
		[string]$RootDirectory,
		[Parameter(Mandatory = $true)]
		[string]$BinaryKey
	);
	
	# DON'T Allow for option of no-key - i.e., I've toyed with idea of "IF THERE'S only one SSMS.exe" in "\binaries\ssms", then just use that. But... i'm not wild about executing .exes someone hasn't manually configured at LEAST the friggin name...
	
	# Allow for hard-coded paths as the 'key' - i.e., overrides of convention can be specified... (e.g., Z:\setup.exe, etc.)
	if (Test-Path -Path $BinaryKey) {
		return $BinaryKey;
	}
	
	[string]$path = Join-Path -Path $RootDirectory -ChildPath "$($BinaryKey).exe";
	if (Test-Path -Path $path) {
		return $path;
	}
	
	[string]$path = Join-Path -Path $RootDirectory -ChildPath "$BinaryKey";
	if (Test-Path -Path $path) {
		return $path;
	}
	
	return $null;
}