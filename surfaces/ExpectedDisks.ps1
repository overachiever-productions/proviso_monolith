Set-StrictMode -Version 1.0;

Surface "ExpectedDisks" -Target "Host" {
	
	Setup {	
		$physicalDisks = Get-ExistingPhysicalDisks;
		$volumes = Get-ExistingVolumeLetters;
		
		$PVContext.SetSurfaceState("CurrentPhysicalDisks", $physicalDisks);
		$PVContext.SetSurfaceState("CurrentVolumes", $volumes);
	}
	
	Assertions {
		Assert-HostIsWindows;
		
		Assert-UserIsAdministrator;
		
		Assert-ConfigIsStrict -FailureMessage "Proviso will NOT [Validate] or [Configure] Disks on systems where Host and TargetServer names do NOT match.";
		
		#region TODO
		# TODO: https://overachieverllc.atlassian.net/browse/PRO-256
		# this is/was using OLDER provisoConfig objects that returned an ENTIRE object... not just key-names (as the new approach does.)
		#   meaning: old code could look at Disk.VolumeNames ... new approach can't. So ... need to fix this. 
#		Assert "C Drive Is NOT Specified" {
#			#Get-ProvisoConfigGroupNames -Config $PVConfig -GroupKey "Host.ExpectedDisks" | ForEach-Object {
#			$PVConfig.GetGroupNames("Host.ExpectedDisks") | ForEach-Object {
#				if (($_.VolumeName -eq "C:\") -or ($_.VolumeName -eq "C")) {
#					throw "Invalid Expected Disk Specification. Proviso can NOT define an expected disk for System (i.e., C:\). Use [Host.Compute.SystemVolumeSize] to define size of C:\ drive instead.";
#				}
#			}
#		}
		#endregion
	}
	
	Aspect -IterateForScope "ExpectedDisks" -OrderByChildKey "ProvisioningPriority"	{
		Facet "PhysicalDiskExists" -Expect $true -NoKey {
			Test {
				$expectedDiskKey = $PVContext.CurrentObjectName;
				$expectedDiskLetter = ($PVConfig.GetValue("Host.ExpectedDisks.$expectedDiskKey.VolumeName") -split "\:")[0];
				$expectedVolumeName = $PVConfig.GetValue("Host.ExpectedDisks.$expectedDiskKey.VolumeLabel");
				
				$existingDisk = $PVContext.GetSurfaceState("CurrentPhysicalDisks") | Where-Object {
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
				$PVContext.WriteLog("Match for [$expectedDiskKey] was Partition [$($partition.PartitionNumber)] (with a size of [$($partition.PartitionSize)]GB) on Disk [$($existingDisk.DiskNumber)] with a total size of [$($existingDisk.SizeInGBs)]GB.", "Verbose");
				
				# TODO: IF we've got any OTHER physical identifiers in the .config... then, compare those and if any fail ... return false and writeLog("why it's not a match", "Important")
				
				return $true;
			}
			Configure {
				# NOTE: Either the expected disk exists ... or it doesn't - there's no logic/path/option for trying to tear-down a disk that already exists... (can't/won't happen). 
				$expectedDiskKey = $PVContext.CurrentObjectName;
				[PSCustomObject]$targetDiskPhysicalIdentifiers = [PSCustomObject]$PVConfig.GetValue("Host.ExpectedDisks.$expectedDiskKey.PhysicalDiskIdentifiers");
				
				# don't use cached disks for determination of which disks are available: 
				$nonInitializedDisks = Get-ExistingPhysicalDisks | Where-Object {
					(-not ($_.IsInitialized))  # only disks without a VOLUME LETTER assigned can/will be considered for use. 
				};
				
				$matchedDiskToConfigure = Match-NonInitializedDisksWithTargetDisk -NonInitializedDisks $nonInitializedDisks -TargetDiskIdentifiers $targetDiskPhysicalIdentifiers -ExpectedDiskName $expectedDiskKey;
				
				if ($null -eq $matchedDiskToConfigure) {
					throw "Could not find an available disk on host matching one or more [PhysicalDiskIdentifiers] for [Host.ExpectedDisks.$expectedDiskKey].";
				}
				
				if ($matchedDiskToConfigure.SizeMatchOnly) {
					$rawSize = $PVConfig.GetValue("Host.ExpectedDisks.$expectedDiskKey.PhysicalDiskIdentifiers.RawSize");
					$PVContext.WriteLog("Physical Disk #[$($matchedDiskToConfigure.DiskNumber)] was a match for [$expectedDiskKey] - matching ONLY on a RawSize of [$rawSize].", "Important");
				}
				else {
					$PVContext.WriteLog("Physical Disk #[$($matchedDiskToConfigure.DiskNumber)] was a match for [$expectedDiskKey] with $($matchedDiskToConfigure.MatchCount) matched attribute(s}: [$($matchedDiskToConfigure.MatchedAttributes)]", "Verbose");
				}
				
				$volumeName = $PVConfig.GetValue("Host.ExpectedDisks.$expectedDiskKey.VolumeName");
				$volumeLabel = $PVConfig.GetValue("Host.ExpectedDisks.$expectedDiskKey.VolumeLabel");
				Initialize-TargetDisk -DiskNumber ($matchedDiskToConfigure.DiskNumber) -DiskName $expectedDiskKey -VolumeName $volumeName -VolumeLabel $volumeLabel;
				
				# Re-set CACHED disk info now that we've changed details: 
				$PVContext.SetSurfaceState("CurrentPhysicalDisks", (Get-ExistingPhysicalDisks));
				$PVContext.SetSurfaceState("CurrentVolumes", (Get-ExistingVolumeLetters));
			}
		}
	}
}