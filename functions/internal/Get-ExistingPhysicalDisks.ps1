Set-StrictMode -Version 1.0;

<#

Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;

With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-ExpectedDisks;

#>

function Get-ExistingPhysicalDisks {
	
	[Proviso.Models.Disk[]]$disks = @();
	
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
				$volumeName = (Get-PSDrive | Where-Object { $_.Name -eq $driveLetter; }).Description;
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