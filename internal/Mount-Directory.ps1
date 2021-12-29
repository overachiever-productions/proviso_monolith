Set-StrictMode -Version 1.0;

filter Mount-Directory {
	
	param (
		[Parameter(Mandatory)]
		[string]$Path
	);
	
	if (!(Test-Path -Path $Path)) {
		New-Item -ItemType Directory -Path $Path | Out-Null;
	}
}