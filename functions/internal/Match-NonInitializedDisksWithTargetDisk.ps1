Set-StrictMode -Version 1.0;

function Match-NonInitializedDisksWithTargetDisk {
	param (
		[Proviso.Models.Disk[]]$NonInitializedDisks,
		[PSCustomObject]$TargetDiskIdentifiers,
		[string]$ExpectedDiskName
	);
	
	begin {
		if ($null -eq $NonInitializedDisks) {
			return $null; # COULD make this a required parameter, but this lets me bypass null-checks within callers... 
		}
		
		$matchedDisks = @();
	}
	
	process {
		$searchAttributes = @{
		};
		if ($TargetDiskIdentifiers.DiskNumber -ne $null) {
			$searchAttributes.Add("DiskNumber", $TargetDiskIdentifiers.DiskNumber);
		}
		if ($TargetDiskIdentifiers.VolumeId -ne $null) {
			$searchAttributes.Add("VolumeId", $TargetDiskIdentifiers.VolumeId);
		}
		if ($TargetDiskIdentifiers.ScsiMapping -ne $null) {
			$searchAttributes.Add("ScsiMapping", $TargetDiskIdentifiers.ScsiMapping);
		}
		if ($TargetDiskIdentifiers.DeviceId -ne $null) {
			$searchAttributes.Add("DeviceId", $TargetDiskIdentifiers.DeviceId);
		}
		if ($TargetDiskIdentifiers.RawSize -ne $null) {
			[int]$rawSize = ($TargetDiskIdentifiers.RawSize) -replace "GB", "";
			$searchAttributes.Add("RawSize", $rawSize);
		}
		
		if ($searchAttributes.Count -lt 1) {
			throw "Invalid Operation. Expected Disk [$ExpectedDiskName] does not have any VALID PhysicalDiskIdentifiers specified.";
		}
		
		
		foreach ($availableDisk in $NonInitializedDisks) {
			
			$availableDiskDetails = @{
			};
			$availableDiskDetails.Add("DiskNumber", $availableDisk.DiskNumber);
			$availableDiskDetails.Add("DeviceID", $availableDisk.DeviceID);
			$availableDiskDetails.Add("ScsiMapping", $availableDisk.ScsiMapping);
			$availableDiskDetails.Add("VolumeId", $availableDisk.VolumeId);
			$availableDiskDetails.Add("RawSize", $availableDisk.SizeInGBs);
			
			[string[]]$matchedAttributes = @();
			foreach ($key in $searchAttributes.Keys) {
				if ($key -eq "RawSize") {
					continue;
				}
				
				if ($searchAttributes.$key -eq $availableDiskDetails.$key) {
					$matchedAttributes += $key;
				}
			}
			
			# now check for disk-size matches: 
			if ($searchAttributes.RawSize -eq $availableDiskDetails.RawSize) {
				if ($matchedAttributes.Count -eq 0) {
					# tag this as a size-only match:
					$availableDisk | Add-Member -MemberType NoteProperty -Name SizeMatchOnly -Value $true;
				}
				
				$matchedAttributes += "RawSize";
			}
			
			# got a match... 
			if ($matchedAttributes.Count -ge 1) {
				$availableDisk | Add-Member -MemberType NoteProperty -Name MatchCount -Value ($matchedAttributes.Count);
				$availableDisk | Add-Member -MemberType NoteProperty -Name MatchedAttributes -Value $matchedAttributes;
				
				$matchedDisks += $availableDisk;
			}
		}
	}
	
	end {
		if ($matchedDisks.Count -gt 0) {
			# Found 1 or more disks ... return the one with the most matches: 
			$output = $matchedDisks | Sort-Object -Property MatchCount -Descending | Select-Object -First 1;
			
			return $output;
		}
	}
}