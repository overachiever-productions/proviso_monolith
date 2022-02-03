Set-StrictMode -Version 1.0;

filter Mount-Directory {
	
	param (
		[Parameter(Mandatory)]
		[string]$Path
	);
	
	if (!(Test-Path -Path $Path)) {
		try {
			New-Item -ItemType Directory -Path $Path -ErrorAction Stop | Out-Null;
		}
		catch {
			throw "Exception Adding Directory: $_ ";
		}
	}
}