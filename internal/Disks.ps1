Set-StrictMode -Version 1.0;

filter Convert-SCSITargetIdToDeviceName {
	<#
	function Convert-SCSITargetIdToDeviceName
	{
	    param([int]$SCSITargetId)
	    If ($SCSITargetId -eq 0) {
	        return "/dev/sda1"
	    }
	    $deviceName = "xvd"
	    If ($SCSITargetId -gt 25) {
	        $deviceName += [char](0x60 + [int]($SCSITargetId / 26))
	    }
	    $deviceName += [char](0x61 + $SCSITargetId % 26)
	    return $deviceName
	}
	#>
	
	param (
		[Parameter(Mandatory)]
		[int]$SCSITargetId
		# vNEXT: Account for SCSIPort in creation/definition of device details.
	);
	
	If ($SCSITargetId -eq 0) {
		return "/dev/sda1";
	}
	
	$deviceName = "xvd";
	If ($SCSITargetId -gt 25) {
		$deviceName += [char](0x60 + [int]($SCSITargetId / 26));
	}
	$deviceName += [char](0x61 + $SCSITargetId % 26);
	
	return $deviceName;
}

filter Get-ExistingPhysicalDisks {
	
	[Proviso.DomainModels.Disk[]]$disks = @();
	
	Get-Disk | ForEach-Object {
		$DiskDrive = $_;
		
		$drivePath = $DiskDrive.Path;
		$size = [math]::Round($DiskDrive.Size/1GB, 2);
		
		$diskNumber = $_.Number;
		$partitions = $_.NumberOfPartitions;
		$volumeID = $_.SerialNumber -replace "_[^ ]*$" -replace "vol", "vol-";
		
		# SCSI Addressing Format: Adapter, Bus/Channel, Target(Id), Lun -> or in Win32_Disk values: Port(Port=Adapter#), Bus, TargetId, LogicalUnit
		$scsiDetails = Get-CimInstance Win32_DiskDrive | Where-Object {
			$_.Index -eq $diskNumber
		};
		$scsiString = "$($scsiDetails.SCSIBus):$($scsiDetails.SCSIPort):$($scsiDetails.SCSITargetId):$($scsiDetails.SCSILogicalUnit)";
		$blockDeviceName = Convert-SCSITargetIdToDeviceName -SCSITargetId $scsiDetails.SCSITargetId;
		
		$disk = New-Object Proviso.DomainModels.Disk($diskNumber, $volumeID, $scsiString, $blockDeviceName, $drivePath, $size);
		
		Get-Partition -DiskNumber $diskNumber -ErrorAction SilentlyContinue | ForEach-Object {
			if ([byte][Char]$_.DriveLetter -ne 0) {
				
				[string]$driveLetter = $null;
				$volumeName = $null;
				
				$driveLetter = $_.DriveLetter;
				$volumeName = (Get-PSDrive | Where-Object {
						$_.Name -eq $driveLetter;
					}).Description;
				$partitionSize = [math]::Round($_.Size/1GB, 2);
				
				if ($driveLetter) {
					$partition = New-Object Proviso.DomainModels.Partition(($_.PartitionNumber), $partitionSize, $driveLetter);
					
					if ($volumeName) {
						$partition.AddLabel($volumeName);
					}
					
					$disk.AddPartition($partition);
				}
			}
		}
		
		$disks += $disk;
	}
	
	return $disks;
}

filter Get-ExistingVolumeLetters {
	Get-Volume | Where-Object {
		$_.DriveLetter -ne $null
	} | Sort-Object -Property DriveLetter | Select-Object -ExpandProperty DriveLetter;
}

function Initialize-TargetDisk {
	param (
		[Parameter(Mandatory)]
		[string]$DiskNumber,
		[Parameter(Mandatory)]
		[string]$DiskName,
		[Parameter(Mandatory)]
		[string]$VolumeName,
		[string]$VolumeLabel
	);
	
	begin {
		[string]$driveLetter = $VolumeName.Replace(":\", "");
		[string]$label = if ([string]::IsNullOrEmpty($VolumeLabel)) {
			$driveLetter
		}
		else {
			$VolumeLabel
		};
	};
	
	process {
		$targetDisk = Get-Disk | Where-Object -Property Number -eq $DiskNumber;
		if ($targetDisk.OperationalStatus -ne "Online") {
			try {
				$targetDisk | Set-Disk -IsOffline $false;
			}
			catch {
				throw "Failure to bring Disk [$DiskName] (Host Disk #[$DiskNumber]) Online: $_  `r`t$($_.ScriptStackTrace)";
			}
		}
		
		# reload:
		$targetDisk = Get-Disk | Where-Object -Property Number -eq $DiskNumber;
		if ($targetDisk.PartitionStyle -eq "RAW") {
			try {
				Initialize-Disk -Number $DiskNumber -PartitionStyle GPT -Confirm:$false;
			}
			catch {
				throw "Failure to Initialize Disk [$DiskName] (Host Disk #[$DiskNumber]): $_  `r`t$($_.ScriptStackTrace)";
			}
		}
		
		try {
			# Sigh. Some real ODDITIES with PowerShell disk formatting operations - meaning that I HAVE to use the exact pattern used below
			#  	or have PROMPTs for the ShellHWDetectionService about format warnings/etc. 
			#   	AS PER: https://social.technet.microsoft.com/Forums/en-US/29abd4e2-d455-4344-ac45-add52adbdf29/newpartition-but-supress-the-dialog?forum=winserverpowershell
			New-Partition -DiskNumber $DiskNumber -UseMaximumSize | Format-Volume -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel $label -Confirm:$false -UseLargeFRS | Out-Null;
			
			# ALSO: i can NOT figure out why I'm assigning a drive-letter to partition 2 (vs 1 - or even 0)... but, it's the ONLY THING that works... 
			Set-Partition -DiskNumber $DiskNumber -PartitionNumber 2 -NewDriveLetter $driveLetter | Out-Null;
		}
		catch {
			throw "Failure to Allocate and Format [$DiskName] (Host Disk #[$DiskNumber)]: $_ `r`n$($_.ScriptStackTrace)";
		}
	};
	
	end {
		$PVContext.WriteLog("Finished Initialize-TargetDisk for [$DiskName] against Disk Number [$DiskNumber].", "Verbose");
	};
}

function Match-NonInitializedDisksWithTargetDisk {
	param (
		[Proviso.DomainModels.Disk[]]$NonInitializedDisks,
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

function Get-DirectoryPermissionsSummary {
	
	param (
		[Parameter(Mandatory)]
		[string]$Directory
	);
	
	if (-not (Test-Path $Directory)) {
		return $null;
	}
	
	(Get-Acl $Directory).Access | Select-Object -Property @{
		Name = 'Access'; Expression = "FileSystemRights";
	}, @{
		Name = "Type"; Expression = "AccessControlType";
	}, @{
		Name = "Account"; Expression = "IdentityReference";
	};
}