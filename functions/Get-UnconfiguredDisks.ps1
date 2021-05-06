Set-StrictMode -Version 1.0;

function Get-UnconfiguredDisks {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$ServerDefinition,
		[Parameter(Mandatory = $true)]
		[string[]]$MountedVolumes
	);
	
	begin {
		if ($MountedVolumes.Count -lt 1) {
			throw "Input or Configuration Error. Parameter -CurrentlyMountedVolumeLetters should contain at least 1 entry (C:\, etc)";
		}
	};
	
	process {
		# Prioritize ExpectedDisks without a matching Volume Assigned by .ProvisioningPriority definition:
		$prioritizedDisks = New-Object "System.Collections.Generic.SortedDictionary[int, string]";
		
		$output = @{};
		
		$decrementKey = [int]::MaxValue;
		[string[]]$keys = $ServerDefinition.ExpectedDisks.Keys;
		foreach ($diskName in $keys) {
			$disk = $ServerDefinition.ExpectedDisks.$diskName;
			
			$driveLetter = $disk.VolumeName.Replace(":\", "");
			if (!($driveLetter -in $MountedVolumes)) {
				[string]$provisioningPriority = $ServerDefinition.ExpectedDisks.$diskName.ProvisioningPriority;
				if ([string]::IsNullOrEmpty($provisioningPriority)) {
					$decrementKey = $decrementKey - 1;
					$provisioningPriority = $decrementKey;
				}
				$prioritizedDisks.Add($provisioningPriority, $diskName)
			}
		}
		
		foreach ($prioritizedKey in $prioritizedDisks.GetEnumerator()) {
			$diskName = $prioritizedKey.Value;
			$disk = $ServerDefinition.ExpectedDisks.$diskName;
			
			$availableDisks = @( Find-NonInitializedDisks );
			
			$targetableDisks = Find-InitializableDiskByIdentifiers -ExpectedDiskName $diskName -PhysicalDiskIdentifiers $disk.PhysicalDiskIdentifiers -AvailableDisksForInit $availableDisks;
			
			# get the best match - based on number of matching specifiers (descending):
			$targetDisk = $targetableDisks | Where-Object {
				$_.MatchCount -gt 0
			} | Sort-Object -Property MatchCount -Descending | Select-Object -First 1;
			
			# check for scenarios where ONLY the target/raw size was specified, and use the FIRST (By DiskNumber) of those if there are any matches:
			if ($targetDisk -eq $null) {
				if ($disk.PhysicalDiskIdentifiers.Count -eq 1) {
					# note this is a bit of a 'cheat' - we KNOW that a single specifier/identifier was defined. And that everything BUT size was a match. So, anything LEFT is a size-match ONLY. 
					$targetDisk = $targetableDisks | Where-Object {
						$_.SizeMatchOnly -eq $true
					} | Sort-Object -Property DiskNumber | Select-Object -First 1;
				}
			}
			
			if ($targetDisk -eq $null) {
				$output[$diskName] = @{
					
					NameOfExpectedDisk 		= $diskName
					ProvisioningPriority 	= $prioritizedKey.Key
					MatchFound		     	= $false		# no match found... 
					
					MatchedPhysicalDisk  	= $null			# empty... 
				};
				
			}
			else {
				$output[$diskName] = @{
					
					NameOfExpectedDisk 		= $diskName
					ProvisioningPriority 	= $prioritizedKey.Key
					MatchFound		     	= $true
					
					MatchedPhysicalDisk  	= $targetDisk
				};
			}
		}
		
		return $output;
	};
	
	end {
		
	};
}