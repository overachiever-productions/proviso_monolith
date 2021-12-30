Set-StrictMode -Version 1.0;

<#

Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;

#With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Validate-ExpectedDisks;
With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Configure-ExpectedDisks;

Summarize -Latest;

#>

Facet "ExpectedDisks" {
	
	Setup {	
		$physicalDisks = Get-ExistingPhysicalDisks;
		$volumes = Get-ExistingVolumeLetters;
		
		#$physicalDisks | Format-List;
		
		$PVContext.AddFacetState("CurrentPhysicalDisks", $physicalDisks);
		$PVContext.AddFacetState("CurrentVolumes", $volumes);
	}
	
	Assertions {
		Assert-HostIsWindows;
		
		Assert-UserIsAdministrator;
		
		Assert -IsNot "C Drive Specified" {
			# TODO: iterate over all disks in Hosts.Expected disks ... 
			#  and, make sure that NONE of them is set to use a volumeName of C:\... 
			
			# if so, throw a ginormous exception... 
			
			# inverted: 
			return $false;
		}
	}
	
	Group-Definitions -GroupKey "Host.ExpectedDisks.*" -OrderByChildKey "ProvisioningPriority"	{
		Definition "PhysicalDiskExists" -Expect $true {
			Test {
				$expectedDiskKey = $PVContext.CurrentKeyValue;
				$expectedDiskLetter = ($PVConfig.GetValue("Host.ExpectedDisks.$expectedDiskKey.VolumeName") -split "\:")[0];
				$expectedVolumeName = $PVConfig.GetValue("Host.ExpectedDisks.$expectedDiskKey.VolumeLabel");
				
				$existingDisk = $PVContext.GetFacetState("CurrentPhysicalDisks") | Where-Object {
					$_.Partitions | Where-Object {
						($_.VolumeName -eq $expectedDiskLetter) -and ($_.VolumeLabel -eq $expectedVolumeName)
					}
				}
				
				if (-not ($existingDisk)) {
					return $false;
				}
				
				$partition = $existingDisk.Partitions | Where-Object {
					($_.VolumeName -eq $expectedDiskLetter) -and ($_.VolumeLabel -eq $expectedVolumeName)
				};
				
				# NOTE: I could also drop the object itself ? into the config? (might need format rules/details?)
				$PVContext.WriteLog("Match for [$expectedDiskKey] was Partition [$($partition.PartitionNumber)] (with a size of [$($partition.PartitionSize)]GB) on Disk [$($existingDisk.DiskNumber)] with a total size of [$($existingDisk.SizeInGBs)]GB.", "Important");
				
				# TODO: IF we've got any OTHER physical identifiers in the .config... then, compare those and if any fail ... return false and writeLog("why it's not a match", "Important")
				
				return $true;
			}
			Configure {
				# NOTE: Either the expected disk exists ... or it doesn't - there's no logic/path/option for trying to tear-down a disk that already exists... (can't/won't happen). 
				$expectedDiskKey = $PVContext.CurrentKeyValue;
				[PSCustomObject]$targetDiskPhysicalIdentifiers = [PSCustomObject]$PVConfig.GetValue("Host.ExpectedDisks.$expectedDiskKey.PhysicalDiskIdentifiers");
				
				$nonInitializedDisks = $PVContext.GetFacetState("CurrentPhysicalDisks") | Where-Object {
					(-not ($_.IsInitialized))
				};
				
Write-Host "Non-initialized: $($nonInitializedDisks.Count) for $expectedDiskKey ";
				
				$matchedDiskToConfigure = Match-NonInitializedDisksWithTargetDisk -NonInitializedDisks $nonInitializedDisks -TargetDisk $targetDiskPhysicalIdentifiers;
				
				if ($null -eq $matchedDiskToConfigure) {
					throw "not able to find a matching disk for $expectedDiskKey ";
				}
				
				Write-Host "Found a match for $expectedDiskKey ";
				
				$expectedDiskLetter = ($PVConfig.GetValue("Host.ExpectedDisks.$expectedDiskKey.VolumeName") -split "\:")[0];
				$expectedVolumeName = $PVConfig.GetValue("Host.ExpectedDisks.$expectedDiskKey.VolumeLabel");
				
				
				
				
				# instead, 
				#  	go back up to the TEST and add in a few other comparisons if/when possible... 
				# 		i.e., try to discriminate like crazy... 
				
				# otherwise... 
				#  IF the disk SHOULD exist and doesn't: 
				#  		get a list of non-initialized disks that I can use. 
				#   	if there's a match... 
				#   		bring the disk online, init, format, and ... create a volume, etc. 
				#   	then refresh disks data... so that recompare can/will work. 
				# ON the odd chance that we somehow get here to where the disk exists and doesn't need to? 
				# 		then... doesn't matter, write/notify that PROVISO will NOT destroy disks. 
				# 		though, honestly, I can't think that we'd ever get into this 'branch' of logic... 
				
				
			}
		}
	}
}

function Match-NonInitializedDisksWithTargetDisk {
	param (
		[Proviso.Models.Disk[]]$NonInitializedDisks,
		[PSCustomObject]$TargetDisk
	);
	
	begin {
		if ($null -eq $NonInitializedDisks) {
			return $null;  # COULD make this a required parameter, but this lets me bypass null-checks within callers... 
		}
	}
}