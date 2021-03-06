Set-StrictMode -Version 1.0;

function Initialize-TargetedDisk {
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$DiskNumber,
		[Parameter(Mandatory = $true)]
		[string]$VolumeName,
		[string]$VolumeLabel
	);
	
	[string]$driveLetter = $VolumeName.Replace(":\", "");
	[string]$label = if ([string]::IsNullOrEmpty($VolumeLabel)) {
		$driveLetter
	}
	else {
		$VolumeLabel
	};
	
	$disk = Get-Disk | Where-Object -Property Number -EQ $DiskNumber;
	if (($disk.PartitionStyle) -eq "Raw" -or ($disk.OperationalStatus) -ne "Online") {
		Initialize-Disk -PartitionStyle GPT -Number $DiskNumber -ErrorAction SilentlyContinue;
	}
	
	# sigh. CAN'T set the volume as part of partition creation without getting the ShewllHWDetection service to throw a warning about needing to format. 
	#   fix for this is the odd sequence/order-of-operations below - thanks to : https://social.technet.microsoft.com/Forums/en-US/29abd4e2-d455-4344-ac45-add52adbdf29/newpartition-but-supress-the-dialog?forum=winserverpowershell
	New-Partition -DiskNumber $DiskNumber -UseMaximumSize | Format-Volume -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel $label -UseLargeFRS;
	Set-Partition -DiskNumber $DiskNumber -PartitionNumber 2 -NewDriveLetter $driveLetter;
}