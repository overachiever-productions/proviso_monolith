Set-StrictMode -Version 1.0;

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
		
		$targetDisk = Get-Disk | Where-Object -Property Number -EQ $DiskNumber;
		
		if (($targetDisk.PartitionStyle -eq "raw") -or ($targetDisk.OperationalStatus -ne "Online")) {
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