Set-StrictMode -Version 1.0;

function Find-MachineDefinition {
	param (
		[Parameter(Mandatory = $true)]
		[string]$RootDirectory,
		[Parameter(Mandatory = $true)]
		[string]$MachineName		
	);
	
	$matches = @{};
	[string[]]$extensions = ".psd1", ".config", ".config.psd1";
	
	$i = 0;
	foreach ($ext in $extensions) {
		foreach ($file in (Get-ChildItem -Path $RootDirectory -Filter "$MachineName$($ext)" -Recurse -ErrorAction SilentlyContinue)) {
			$matches[$i] = @{
				Name = $file.FullName;
				Size = $file.Length / 1KB
				Modified = $file.LastWriteTime;
			};
			
			$i++;
		}
	}
	
	return $matches;
}