Set-StrictMode -Version 1.0;

function Confirm-DiskConfiguration {
	
	#[cmdletbinding(SupportsShouldProcess = $true)];
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$PathToConfigFile
	);
	
	begin {
		
	}
	
	process {
		
		[PSCustomObject]$definition = Read-ServerDefinitions -Path $PathToConfigFile -Strict;
		
		$mountedVolumes = Get-ExistingVolumesByLetter;
		
		Initialize-DisksFromDefinitions -ServerDefinition $definition -CurrentlyMountedVolumeLetters $mountedVolumes -ProcessEphemeralDisksOnly -Strict;
	}
	
	end {
		
	}
}
