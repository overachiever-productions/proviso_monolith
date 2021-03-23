Set-StrictMode -Version 1.0;

# 	'Overload' / 'Hard-Alias' of Initialize-DefinedDisks. See https://stackoverflow.com/questions/55539278/ and https://stackoverflow.com/a/63292585/11191

function Confirm-DefinedDisks {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$ServerDefinition,
		[Parameter(Mandatory = $true)]
		[string[]]$CurrentlyMountedVolumeLetters
	);
	
	begin {
	}
	
	process {
		Initialize-DefinedDisks -ServerDefinition $ServerDefinition -CurrentlyMountedVolumeLetters $CurrentlyMountedVolumeLetters -Strict -ProcessEphemeralDisksOnly;
	}
	
	end {
	}
}