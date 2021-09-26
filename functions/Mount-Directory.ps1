Set-StrictMode -Version 1.0;

function Mount-Directory {
	
	param (
		[string]$Path
	);
	
	if (!(Test-Path -Path $Path)) {
		New-Item -ItemType Directory -Path $Path | Out-Null;
	}
}