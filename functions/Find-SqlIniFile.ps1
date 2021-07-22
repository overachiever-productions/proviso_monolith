Set-StrictMode -Version 1.0;

function Find-SqlIniFile {
	param (
		[Parameter(Mandatory = $true)]
		[string]$RootDirectory,
		[Parameter(Mandatory = $true)]
		[string]$IniKey
	);
	
	# Allow for hard-coded paths as the 'key' - i.e., overrides of convention can be specified... (e.g., C:\CORPORATE_SQL.ini, etc.)
	if (Test-Path -Path $IniKey) {
		return $IniKey;
	}
	
	[string]$path = Join-Path -Path $RootDirectory -ChildPath "$($IniKey).ini";
	if (Test-Path -Path $path) {
		return $path;
	}
	
	$path = Join-Path -Path $RootDirectory -ChildPath $IniKey;
	if (Test-Path -Path $path) {
		return $path;
	}
	
	return $null;
}