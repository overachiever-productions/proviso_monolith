Set-StrictMode -Version 1.0;

# Refactor: Resolve-IdentifiableDisks

function Find-InitializableDiskByIdentifiers {
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$ExpectedDiskName,
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$PhysicalDiskIdentifiers,
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$AvailableDisksForInit
	)
	
	# if there are NO available drives, we're done.
	if ($AvailableDisksForInit.Count -eq 0) {
		return;
	}
	
	# if there are > 1 drives available, we'll have to filter to determine the CORRECT match. (And if we get > 1 'correct' match, we use the one with the lowest DiskNumber)
	$searchAttributes = @{
	};
	
	if ($PhysicalDiskIdentifiers.DiskNumber -ne $null) {
		$searchAttributes.Add("DiskNumber", $PhysicalDiskIdentifiers.DiskNumber);
	}
	if ($PhysicalDiskIdentifiers.DeviceID -ne $null) {
		$searchAttributes.Add("DeviceID", $PhysicalDiskIdentifiers.DeviceID);
	}
	if ($PhysicalDiskIdentifiers.ScsiMapping -ne $null) {
		$searchAttributes.Add("ScsiMapping", $PhysicalDiskIdentifiers.ScsiMapping);
	}
	if ($PhysicalDiskIdentifiers.VolumeId -ne $null) {
		$searchAttributes.Add("VolumeId", $PhysicalDiskIdentifiers.VolumeId);
	}
	if ($PhysicalDiskIdentifiers.RawSize -ne $null) {
		$searchAttributes.Add("RawSize", $PhysicalDiskIdentifiers.RawSize.Replace(" ", ""));
	}
	
	if ($searchAttributes.Count -lt 1) {
		throw "Invalid Physical Disk Specifications Provided - no matching disk attributes defined.";
	}
	
	$matches = @();
	
	foreach ($drive in $AvailableDisksForInit) {
		$driveDetails = @{
		};
		
		$driveDetails.Add("DiskNumber", $drive.DiskNumber);
		$driveDetails.Add("DeviceID", $drive.DeviceID);
		$driveDetails.Add("ScsiMapping", $drive.ScsiMapping);
		$driveDetails.Add("VolumeId", $drive.VolumeId);
		$driveDetails.Add("RawSize", $drive.Size.Replace(" ", ""));
		
		$matchCount = 0;
		foreach ($key in $searchAttributes.Keys) {
			
			if ($key -eq "RawSize") {
				continue;
			}
			
			if ($driveDetails.$key -eq $searchAttributes.$key) {
				$matchCount = $matchCount + 1;
			}
		}
		
		if ($matchCount -ge 1) {
			$drive | Add-Member -MemberType NoteProperty -Name MatchCount -Value $matchCount;
			
			$matches += $drive;
		}
		
		if ($matchCount -eq 0) {
			# check for size-only matches:
			if ($driveDetails.RawSize -eq $searchAttributes.RawSize) {
				$drive | Add-Member -MemberType NoteProperty -Name MatchCount -Value 0;
				$drive | Add-Member -MemberType NoteProperty -Name SizeMatchOnly -Value $true;
				
				$matches += $drive;
			}
		}
		else {
			# matches against size are STILL valid matches - we just want to differentiate between scenarios where we ONLY
			#    match on size vs those where size is ALSO a match... ergo the logic below - which increments for non-SizeMatchOnly operations.
			if ($driveDetails.RawSize -eq $searchAttributes.RawSize) {
				$drive.MatchCount = $drive.MatchCount + 1;
			}
		}
	}
	
	return $matches;
}