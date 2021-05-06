Set-StrictMode -Version 1.0;

# NOTE: Near-Duplicate functionality also exists in Confirm-DefinedDisks (via OCP-adapter.)

function Initialize-DefinedDisks {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$ServerDefinition,
		[Parameter(Mandatory = $true)]
		[string[]]$CurrentlyMountedVolumes,
		[switch]$ProcessEphemeralDisksOnly = $true,
		[switch]$Strict = $true
	);
	
	begin {
		# Verify Strict:
		if ($Strict) {
			$currentHostName = $env:COMPUTERNAME;
			if ($currentHostName -ne $ServerDefinition.TargetServer) {
				throw "HostName defined by -ServerDefinition [$($ServerDefinition.TargetServer)] does NOT match current server hostname [$currentHostName]. Processing Aborted."
			}
		}
	};
	
	process {
		# TODO: this needs to be a prioritized list:
		#    er... actually, if I can do soemthing like > foreach ($key in $expectedDisks.Keys | OrderBy whatever... ) then... done (ish)
		$expectedDisks = Get-UnconfiguredDisks -ServerDefinition $ServerDefinition -MountedVolumes $CurrentlyMountedVolumes;
		
		if ($expectedDisks.Count -eq 0) {
			# if Verbose or if ... something else... Write-Host "All Disks defined in config file were found and already provisioned/configured.";
			return;
		}
		
		foreach ($key in $expectedDisks.Keys) {
			$disk = $expectedDisks[$key];
			$definedDisk = $ServerDefinition.ExpectedDisks[$disk.NameOfExpectedDisk];
			
			if ($disk.MatchFound) {
				
				$diskNumber = $disk.MatchedPhysicalDisk.DiskNumber;
				
				try {
					Initialize-TargetedDisk -DiskNumber $diskNumber -VolumeName $definedDisk.VolumeName -VolumeLabel $definedDisk.VolumeLabel;
				}
				catch {
					throw "Exception attempting to Initialize Disk $($disk.MatchedPhsycialDisk.DiskNumber) as $($definedDisk.VolumeName).`n`n`tException: $($_).";
				}
			}
			else {
				if ($Strict) {
					throw "Fatal Exception: Expected Disk for $($definedDisk.VolumeName) not found - no matches available. Disk cannot be provisioned.";
				}
			}
		};
	}
	
	end {
		
	};
}