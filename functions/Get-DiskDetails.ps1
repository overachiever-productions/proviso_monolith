Set-StrictMode -Version 1.0;

function Get-DiskDetails {
	
	Get-disk | ForEach-Object {
		$DiskDrive = $_;
		
		$DrivePath = $DiskDrive.Path;
		$Size = $DiskDrive.Size;
		$Size = [math]::Round($DiskDrive.Size/1GB, 2);
		
		$Disk = $_.Number;
		$Partitions = $_.NumberOfPartitions;
		$VolumeID = $_.SerialNumber -replace "_[^ ]*$" -replace "vol", "vol-";
		
		[string]$DriveLetter = "N/A";
		$VolumeName = $null;
		
		Get-Partition -DiskNumber 0 | ForEach-Object {
			if ([byte][Char]$_.DriveLetter -ne 0) {
				$DriveLetter = $_.DriveLetter;
				$VolumeName = (Get-PSDrive | Where-Object {
						$_.Name -eq $DriveLetter
					}).Description;
			}
		}
		
		# SCSI Addressing Format: Adapter, Bus/Channel, Target(Id), Lun -> or in Win32_Disk values: Port(Port=Adapter#), Bus, TargetId, LogicalUnit
		$scsiDetails = Get-CimInstance Win32_DiskDrive | Where-Object {
			$_.Index -eq $Disk
		};
		$scsiString = "$($scsiDetails.SCSIBus):$($scsiDetails.SCSIPort):$($scsiDetails.SCSITargetId):$($scsiDetails.SCSILogicalUnit)";
		
		$BlockDeviceName = Convert-SCSITargetIdToDeviceName -SCSITargetId $scsiDetails.SCSITargetId;
		
		New-Object PSObject -Property @{
			DiskNumber  = $Disk;
			Path	    = $DrivePath;
			Size	    = "$Size GB";
			Partitions  = $Partitions;
			DriveLetter = if ([string]::IsNullOrEmpty($DriveLetter)) {
				"N/A"
			} Else {
				$DriveLetter
			};
			VolumeId    = if ($VolumeID -eq $null) {
				"N/A"
			} Else {
				$VolumeID
			};
			DeviceId    = if ($BlockDeviceName -eq $null) {
				"N/A"
			} Else {
				$BlockDeviceName
			};
			#VirtualDevice = If ($VirtualDevice -eq $null) { "N/A" } Else { $VirtualDevice };
			VolumeName  = if ($VolumeName -eq $null) {
				"N/A"
			} Else {
				$VolumeName
			};
			ScsiMapping = if ($scsiString -eq $null) {
				"N/A"
			} Else {
				$scsiString
			};
		}
		
		# vNEXT: based on what kind of 'identifiers' we're getting back (and/or via a -Platform parameter), pass this object off/into a 'parser'/provider-ish
		#    function that'll tweak and format the details above to better account for various 'quirks' of each environment/platform (Physical, VMware, AWS, Azure, etc.)
	}
}