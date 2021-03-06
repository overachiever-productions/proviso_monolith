$root = Split-Path -Parent $MyInvocation.MyCommand.Path.Replace("\tests", "\functions");
$sut = Split-Path -Leaf $MyInvocation.MyCommand.Path.Replace(".Tests.", ".");
$functionName = $sut.Replace(".ps1", "");

. "$root\$sut";

function Read-FakedIdentifiers {
	$faked = @{
		TargetServer = "AWS-SQL-1B"
		
		HostName	 = @{
			DomainName  = "aws.local"
			MachineName = "AWS-SQL-1B"
		}
		
		ExpectedDisks = @{
			
			DataDisk = @{
				ProvisioningPriority    = 1
				
				VolumeName			    = "D:\"
				VolumeLabel			    = "SQLData"
				
				PhysicalDiskIdentifiers = @{
					RawSize = "40GB"
				}
				
				ExpectedDirectories	    = @{
					
					# Directories that NT SERVICE\MSSQLSERVER can access (full perms)
					VirtualSqlServerServiceAccessibleDirectories = @(
						"D:\SQLData"
						"D:\Traces"
					)
					
					# Additional/Other Directories - but no perms granted to SQL Server service.
					RawDirectories							     = @(
						"D:\SampleDirectory"
					)
				}
			}
			
			BackupsDisk = @{
				ProvisioningPriority    = 3
				
				VolumeName			    = "E:\"
				VolumeLabel			    = "SQLBackups"
				
				PhysicalDiskIdentifiers = @{
					RawSize = "60GB"
				}
				
				ExpectedDirectories	    = @{
					
					# Directories that NT SERVICE\MSSQLSERVER can access (full perms)
					VirtualSqlServerServiceAccessibleDirectories = @(
						"E:\SQLBackups"
					)
					
					# Additional/Other Directories - but no perms granted to SQL Server service.
					RawDirectories							     = @(
						"E:\Archived"
					)
				}
				
				SharedDirectories	    = @{
					
					SqlBackups = @{
						SourceDirectory = "E:\SQLBackups"
						ShareName	    = "SQLBackups"
						ReadOnlyAccess  = @()
						ReadWriteAccess = @(
							"aws\sqlservice"
						)
					}
				}
			}
			
			TempdbDisk = @{
				
				VolumeName			    = "F:\"
				VolumeLabel			    = "SQLTempDB"
				
				PhysicalDiskIdentifiers = @{
					RawSize    = "30GB"
				}
				
				ExpectedDirectories	    = @{
					VirtualSqlServerServiceAccessibleDirectories = @(
						"F:\SQLTempDB"
						"F:\Traces"
					)
				}
			}
		}
	}
	
	return $faked;
}

function Read-FakedServerDisks {
	$fakeDisk1 = New-Object PSObject -Property @{
		DiskNumber  = 1;
		Path	    = "\\?\scsi#disk&ven_vmware&prod_virtual_disk#5&3862831b&0&000a00#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}";
		Size	    = "44 GB";
		Partitions  = 2;
		DriveLetter = "D";
		VolumeId    = "6000c2903aa7073c851d4eab74af1d22";
		DeviceId    = "xvdk";
		VolumeName  = "Data";
		ScsiMapping = "0:2:10:0";
	};
	
	$fakeDisk2 = New-Object PSObject -Property @{
		DiskNumber  = 2;
		Path	    = "\\?\scsi#disk&ven_vmware&prod_virtual_disk#5&3862831b&0&000a00#{53f56307-8890-11d0-94f2-00a0c91efb8b}";
		Size	    = "30 GB";
		Partitions  = 2
		DriveLetter = "E";
		VolumeId    = "6000c2903aa8003c851d4eab74af1dbe";
		DeviceId    = "xvdv";
		VolumeName  = "Media";
		ScsiMapping = "0:4:8:0";
	};
	
	$fakeDisk3 = New-Object PSObject -Property @{
		DiskNumber  = 3;
		Path	    = "\\?\scsi#disk&ven_vmware&prod_virtual_disk#5&3862831b&0&000a00#{53f56307-2234-11d0-94f2-00a0c91efb8b}";
		Size	    = "30 GB";
		Partitions  = 0;
		DriveLetter = "N/A";
		VolumeId    = "6000c2903aa2003c851d4eab74af1dbe";
		DeviceId    = "xvii";
		VolumeName  = "N/A";
		ScsiMapping = "0:1:2:2";
	};
	
	$fakeDisk4 = New-Object PSObject -Property @{
		DiskNumber  = 5;
		Path	    = "\\?\scsi#disk&ven_vmware&prod_virtual_disk#5&3862831b&0&000a00#{53f56307-aacc-11d0-94f2-00a0c91efb8b}";
		Size	    = "60 GB";
		Partitions  = 0;
		DriveLetter = "N/A";
		VolumeId    = "6000c2903aaaac3c851d4eab74af1dbe";
		DeviceId    = "xvnii";
		VolumeName  = "N/A";
		ScsiMapping = "0:1:2:6";
	};
	
	return @($fakeDisk1, $fakeDisk2, $fakeDisk3, $fakeDisk4);
}

function Read-FakedMatchFrom_FindInitializableDiskByIdentifiers {
	$match = @{
		DiskNumber 	= 3
		DeviceId   	= "xvii"
		ScsiMapping = "0:1:2:2"
		VolumeId    = "6000c2903aa2003c851d4eab74af1dbe"
		RawSize	    = "30GB"
		MatchCount  = 0
		SizeMatchOnly = $true
	};
	
	return $match;
}

function Read-FakedMatch2From_FindInitializableDiskByIdentifiers {
	$match = @{
		DiskNumber    = 5
		DeviceId	  = "xvnii"
		ScsiMapping   = "0:1:2:6"
		VolumeId	  = "6000c2903aaaac3c851d4eab74af1dbe"
		RawSize	      = "60GB"
		MatchCount    = 0
		SizeMatchOnly = $true
	};
	
	return $match;
}

#region Fakes
function Find-NonInitializedDisks {
	return Read-FakedServerDisks | Where-Object {
		$_.DriveLetter -eq "N/A"
	};
}

$global:maxInt = [int]::MaxValue;

function Find-InitializableDiskByIdentifiers {
	param (
		[Parameter(Mandatory = $true)]
		[string]$ExpectedDiskName,
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$PhysicalDiskIdentifiers,
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$AvailableDisksForInit
	)
	
	if ($ExpectedDiskName -eq "TempdbDisk") {
		return Read-FakedMatchFrom_FindInitializableDiskByIdentifiers;
	}
}
#endregion

Describe "Unit Tests for $functionName" -Tag "UnitTests" {
	
	Context "Input Validation" {
		
		# NOT NECESSARY - as PowerShell throws: "Cannot bind argument to parameter 'CurrentlyMountedVolumeLetters' because it is an empty array" when empty. 
		#It "Should Throw if There is Not At Least One Currently Mounted Volume" {
	}
	
	Context "Dependency Validation" {
# yeah... no it shouldn't. This is code that belongs in the 'controller' - not in this function which is ONLY concerned with merging/matching disks by priority/rank/etc.
#		It "Should Check If SQL Server Service Exists" {
#			Mock Get-Service {
#				return $null;
#			} -Verifiable -ParameterFilter { $Name -eq "MSSQLSERVER"};
#			
#			$serverDefinition = @{
#				TargetServer = "AWS-SQL-1B"
#			};
#			
#			$mountedVolumes = @("C", "D", "E");
#			
#			Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $mountedVolumes;
#			
#			Assert-MockCalled Get-Service -Times 1 -ParameterFilter { $Name -eq "MSSQLSERVER" };
#		}
		
		It "Should Call Find-NonInitializedDisks to Find Available Disks" {
			$serverDefinition = Read-FakedIdentifiers;
			$mountedVolumes = @("C", "D", "E");  # Note: Test case here is that Drive F:\ (30GB drive) is missing... (and should match on faked diskNumber 3 (by size only))
			
			Mock Find-NonInitializedDisks {
				return Read-FakedServerDisks | Where-Object { $_.DriveLetter -eq "N/A" };
			};
			
			Mock Find-InitializableDiskByIdentifiers {
				return Read-FakedMatchFrom_FindInitializableDiskByIdentifiers;
			}			
			
			Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $mountedVolumes;
			
			Assert-MockCalled Find-NonInitializedDisks -Times 1;
		}
				
		It "Should Call Find-InitializableDiskByIdentifiers for Matching Purposes" {
			$serverDefinition = Read-FakedIdentifiers;
			$mountedVolumes = @("C", "D", "E", "F");
			
			Mock Find-NonInitializedDisks {
				return Read-FakedServerDisks | Where-Object { $_.DriveLetter -eq "N\A" };
			};
			
			Mock Find-InitializableDiskByIdentifiers {
				return Read-FakedMatchFrom_FindInitializableDiskByIdentifiers;
			}
			
			{ Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $mountedVolumes }
			
			Assert-MockCalled Find-InitializableDiskByIdentifiers -Times 1;
		}
	}

	Context "Functional Validation" {
		It "Should NOT Match Identifiers for Expected Disks That Are Already Defined" {
			$serverDefinition = Read-FakedIdentifiers;
			$mountedVolumes = @("C", "D", "E", "F");  # All ExpectedDisks are/have-been mounted and have volumes/etc. (i.e., 'nothing to do here'...)
			
			# no need to Mock calls to dependent functions - they shouldn't get called. 
			
			# instead: expect NULL in terms of results.
			$results = Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $mountedVolumes;
			$results | Should -BeNullOrEmpty;
		}
		
		It "Should NOT Attempt Dependency Processing to Match Expected Disks That Are Already Defined" {
			$serverDefinition = Read-FakedIdentifiers;
			$mountedVolumes = @("C", "D", "E", "F"); # All ExpectedDisks are/have-been mounted and have volumes/etc. (i.e., 'nothing to do here'...)
			
			Mock Find-InitializableDiskByIdentifiers {
				return $null;
			};
			
			$results = Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $mountedVolumes;
			
			Assert-MockCalled Find-InitializableDiskByIdentifiers -Times 0;
		}
		
		It "Should NOT Throw When NO Non-Initialized Disks Exist" {
			$serverDefinition = Read-FakedIdentifiers;
			$mountedVolumes = @("C", "D", "E"); # Expect F:\ but... don't get a match...
			
			Mock Find-InitializableDiskByIdentifiers {
				return $null; # force/fake no-matches.
			}
			
			Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $mountedVolumes;
		}
		
		It "Should Specify Non-Matched When Matches Are Not Found" {
			$serverDefinition = Read-FakedIdentifiers;
			$mountedVolumes = @("C", "D", "E"); # Expect F:\ but... don't get a match...
			
			Mock Find-InitializableDiskByIdentifiers {
				return $null; # force/fake no-matches.
			}
			
			$results = Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $mountedVolumes;
			
			$results.Count | Should -Be 1;
			$results["TempDbDisk"].NameOfExpectedDisk | Should -Be "TempDbDisk";
			$results["TempDbDisk"].MatchFound | Should -Be $false;
		}
		
		It "Should Assign Default (Low) ProvisioningPriorities To Disks Without Explicit Values" {
			[PSCustomObject]$serverDefinition = Read-FakedIdentifiers;
			$mountedVolumes = @("C", "D", "E"); # only F:\ is mising... 
			
			# Mock for missing F:\ drive
			Mock Find-InitializableDiskByIdentifiers -MockWith {
				[PSCustomObject]@{
					DiskNumber    = 3
					DeviceId	  = "xvii"
					ScsiMapping   = "0:1:2:2"
					VolumeId	  = "6000c2903aa2003c851d4eab74af1dbe"
					RawSize	      = "30GB"
					MatchCount    = 0
					SizeMatchOnly = $true
				};
			} -ParameterFilter {
				$ExpectedDiskName -eq "TempdbDisk"
			}

			$results = Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $mountedVolumes;
			$results.Keys.Count | Should -Be 1;
			
			$max = [int]::MaxValue;
			$results["TempDbDisk"].ProvisioningPriority | Should -Be $max;
		}
		
		# No. It should RANK OUTPUTs by priority (but the order in which it processes matches is irrelevant)... 
		#   BUT: the caller/consumer/controller should process stuff IN ORDER
		#   cuz, the concern here is that if we have 2x ExpectedDisks that 'want' the same disk, the one with the higher priority should 'take' it before the lower priority one gets a chance
#		It "Should Prioritize Processing of ExpectedDisks Against Provisioning Priority" {
			
		It "Should Translate Volume Names to Drive Letters" {
			$serverDefinition = @{
				ExpectedDisks = @{
					
					DataDisk = @{
						ProvisioningPriority    = 1
						
						VolumeName			    = "D:\"
						VolumeLabel			    = "SQLData"
						
						PhysicalDiskIdentifiers = @{
							RawSize = "40GB"
						}
						
						ExpectedDirectories	    = @{
							
							# Directories that NT SERVICE\MSSQLSERVER can access (full perms)
							VirtualSqlServerServiceAccessibleDirectories = @(
								"D:\SQLData"
								"D:\Traces"
							)
							
							# Additional/Other Directories - but no perms granted to SQL Server service.
							RawDirectories							     = @(
								"D:\SampleDirectory"
							)
						}
					}
				}
			}
			$mountedVolumes = @("C", "E"); # Expect D:\ but... not provisioned yet. 
			
			Mock Find-InitializableDiskByIdentifiers {
				Read-FakedMatch2From_FindInitializableDiskByIdentifiers;
			} -Verifiable -ParameterFilter {
				$ExpectedDiskName -eq "DataDisk"
			};
			
			Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $mountedVolumes;
			
			# if we attempt to find for D:\ (via input/config data) vs/against D (volume letter only), then translation occurred. 
			Assert-MockCalled Find-InitializableDiskByIdentifiers -Times 1 -ParameterFilter {
				$ExpectedDiskName -eq "DataDisk"
			};
		}
		
		It "Should Return Physical Disk Identerifiers Match-Count and Physical Disk Details" {
			$serverDefinition = @{
				ExpectedDisks = @{
					
					DataDisk = @{
						ProvisioningPriority    = 1
						
						VolumeName			    = "D:\"
						VolumeLabel			    = "SQLData"
						
						PhysicalDiskIdentifiers = @{
							RawSize = "50GB"
						}
						
						ExpectedDirectories	    = @{
							
							# Directories that NT SERVICE\MSSQLSERVER can access (full perms)
							VirtualSqlServerServiceAccessibleDirectories = @(
								"D:\SQLData"
								"D:\Traces"
							)
							
							# Additional/Other Directories - but no perms granted to SQL Server service.
							RawDirectories							     = @(
								"D:\SampleDirectory"
							)
						}
					}
				}
			}
			$mountedVolumes = @("C", "E"); # Expect D:\ but... not provisioned yet. 
			
			Mock Find-InitializableDiskByIdentifiers {
				return @{
					DiskNumber    = 5
					DeviceId	  = "xvnii"
					ScsiMapping   = "0:1:2:6"
					VolumeId	  = "6000c2903aaaac3c851d4eab74af1dbe"
					RawSize	      = "50GB"
					MatchCount    = 3
					SizeMatchOnly = $false
				};
			} -Verifiable -ParameterFilter {
				$ExpectedDiskName -eq "DataDisk"
			};
			
			$results = Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $mountedVolumes;
			$results.Count | Should -Be 1;
			$results["DataDisk"].MatchFound | Should -Be $true;
			#$results["DataDisk"].MatchDetails.CountOfMatchablePhysicalDisks | Should -Be 2;
			$results["DataDisk"].MatchedPhysicalDisk.RawSize | Should -Be "50GB";
			$results["DataDisk"].MatchedPhysicalDisk.DiskNumber | Should -Be 5;
			$results["DataDisk"].MatchedPhysicalDisk.MatchCount | Should -Be 3;
			$results["DataDisk"].MatchedPhysicalDisk.SizeMatchOnly | Should -Be $false;
		}
		
		It "Should Handle Matching Operations for Multiple Missing Disks" {
			[PSCustomObject]$serverDefinition = Read-FakedIdentifiers;
			$mountedVolumes = @("C", "D"); # Assume that E:\ and F:\ are missing - E should be processed first... 
			
			# Mock for missing E:\ drive (note, ParameterFilter actually doesn't work... not that that matters tooo much)
			Mock Find-InitializableDiskByIdentifiers {
				return Read-FakedMatch2From_FindInitializableDiskByIdentifiers; 
			} -Verifiable -ParameterFilter {
				$PhysicalDiskIdentifiers.RawSize -eq "60GB"
			};
			
			# Mock for missing F:\ drive
			Mock Find-InitializableDiskByIdentifiers {
				return Read-FakedMatchFrom_FindInitializableDiskByIdentifiers;
			} -Verifiable -ParameterFilter {
				$PhysicalDiskIdentifiers.RawSize -eq "30GB"
			};
			
			$results = Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $mountedVolumes;
			
			Assert-MockCalled Find-InitializableDiskByIdentifiers -Times 1 -ParameterFilter {
				$PhysicalDiskIdentifiers.RawSize -eq "60GB"
			};
			
			Assert-MockCalled Find-InitializableDiskByIdentifiers -Times 1 -ParameterFilter {
				$PhysicalDiskIdentifiers.RawSize -eq "30GB"
			};
			
			$results.Keys.Count | Should -Be 2;
			$results["BackupsDisk"].ProvisioningPriority | Should -Be 3;
			$results["TempDbDisk"].ProvisioningPriority | Should -Be $global:maxInt;
			
			$results["BackupsDisk"].MatchFound | Should -Be $true;
			$results["TempDbDisk"].MatchFound | Should -Be $true;
		}
		
		It "Should Allow for Size-Only Matches when No Other Identifiers Match" {
			$serverDefinition = @{
				ExpectedDisks = @{
					
					DataDisk = @{
						ProvisioningPriority    = 1
						
						VolumeName			    = "D:\"
						VolumeLabel			    = "SQLData"
						
						PhysicalDiskIdentifiers = @{
							RawSize = "50GB"
						}
						
						ExpectedDirectories	    = @{
							
							# Directories that NT SERVICE\MSSQLSERVER can access (full perms)
							VirtualSqlServerServiceAccessibleDirectories = @(
								"D:\SQLData"
								"D:\Traces"
							)
							
							# Additional/Other Directories - but no perms granted to SQL Server service.
							RawDirectories							     = @(
								"D:\SampleDirectory"
							)
						}
					}
				}
			}
			$mountedVolumes = @("C", "E"); # Expect D:\ but... not provisioned yet. 
			
			Mock Find-InitializableDiskByIdentifiers {
				return @{
					DiskNumber    = 5
					DeviceId	  = "xvnii"
					ScsiMapping   = "0:1:2:6"
					VolumeId	  = "6000c2903aaaac3c851d4eab74af1dbe"
					RawSize	      = "60GB"
					MatchCount    = 0
					SizeMatchOnly = $true
				};
			} -Verifiable -ParameterFilter {
				$ExpectedDiskName -eq "DataDisk"
			};
			
			$results = Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $mountedVolumes;
			$results.Count | Should -Be 1;
			$results["DataDisk"].MatchFound | Should -Be $true;
			$results["DataDisk"].MatchedPhysicalDisk.RawSize | Should -Be "60GB";
			$results["DataDisk"].MatchedPhysicalDisk.DiskNumber | Should -Be 5;
			$results["DataDisk"].MatchedPhysicalDisk.MatchCount | Should -Be 0;
			$results["DataDisk"].MatchedPhysicalDisk.SizeMatchOnly | Should -Be $true;
		}
		
		It "Should Rank Disks with More Matches Before Disks with Fewer Matches" {
			$serverDefinition = @{
				ExpectedDisks = @{
					
					DataDisk = @{
						ProvisioningPriority    = 1
						
						VolumeName			    = "D:\"
						VolumeLabel			    = "SQLData"
						
						PhysicalDiskIdentifiers = @{
							RawSize = "50GB"
							DiskNumber = 7
						}
						
						ExpectedDirectories	    = @{
							
							# Directories that NT SERVICE\MSSQLSERVER can access (full perms)
							VirtualSqlServerServiceAccessibleDirectories = @(
								"D:\SQLData"
								"D:\Traces"
							)
							
							# Additional/Other Directories - but no perms granted to SQL Server service.
							RawDirectories							     = @(
								"D:\SampleDirectory"
							)
						}
					}
				}
			}
			$mountedVolumes = @("C", "E"); # Expect D:\ but... not provisioned yet. 
			
			Mock Find-InitializableDiskByIdentifiers {
				$disk1 = @{
					DiskNumber    = 5
					DeviceId	  = "xvnii"
					ScsiMapping   = "0:1:2:5"
					VolumeId	  = "5000c2903aaaac3c851d4eab74af1dbe"
					RawSize	      = "50GB"
					MatchCount    = 0
					SizeMatchOnly = $true
				};
				
				$disk2 = @{
					DiskNumber    = 6
					DeviceId	  = "xvniv"
					ScsiMapping   = "0:1:2:6"
					VolumeId	  = "6000c2903aaaac3c851d4eab74af1dbe"
					RawSize	      = "50GB"
					MatchCount    = 0
					SizeMatchOnly = $true
				};
				
				$disk3 = @{
					DiskNumber    = 7
					DeviceId	  = "xvniii"
					ScsiMapping   = "0:1:2:7"
					VolumeId	  = "7000c2903aaaac3c851d4eab74af1dbe"
					RawSize	      = "50GB"
					MatchCount    = 2
					SizeMatchOnly = $false
				};
				
				return @($disk1, $disk2, $disk3)
			} -Verifiable -ParameterFilter {
				$ExpectedDiskName -eq "DataDisk"
			};
			
			$results = Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $serverDefinition -CurrentlyMountedVolumeLetters $mountedVolumes;
			$results.Count | Should -Be 1;
			$results["DataDisk"].MatchFound | Should -Be $true;
			$results["DataDisk"].MatchedPhysicalDisk.RawSize | Should -Be "50GB";
			$results["DataDisk"].MatchedPhysicalDisk.DiskNumber | Should -Be 7;
			$results["DataDisk"].MatchedPhysicalDisk.MatchCount | Should -Be 2;
			$results["DataDisk"].MatchedPhysicalDisk.SizeMatchOnly | Should -Be $false;
		}
	}
	
}

Describe "Integration Tests for $functionName" -Tag "UnitTests" {
	
	
}