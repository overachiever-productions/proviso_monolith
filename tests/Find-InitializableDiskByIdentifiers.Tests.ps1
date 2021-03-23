#. ..\internal\Find-InitializableDiskByIdentifiers.ps1

BeforeAll {
	
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "\internal");
	$sut = Split-Path -Leaf $PSCommandPath.Replace(".Tests.", ".");
	$functionName = $sut.Replace(".ps1", "");
	
	. "$root\$sut";
	
	function Read-FakeConfigData {
		$config = @{
			
			TargetServer  = "AWS-SQL-1B"
			
			ExpectedDisks = @{
				
				DataDisk = @{
					ProvisioningPriority    = 1
					
					VolumeName			    = "D:\"
					VolumeLabel			    = "SQLData"
					
					PhysicalDiskIdentifiers = @{
						RawSize = "40GB"
					}
				}
				
				BackupsDisk = @{
					ProvisioningPriority    = 3
					
					VolumeName			    = "E:\"
					VolumeLabel			    = "SQLBackups"
					
					PhysicalDiskIdentifiers = @{
						RawSize = "60GB"
					}
				}
				
				TempdbDisk = @{
					
					VolumeName			    = "F:\"
					VolumeLabel			    = "SQLTempDB"
					
					PhysicalDiskIdentifiers = @{
						RawSize    = "30GB"
						DiskNumber = "3"
						DeviceId   = "xvdd"
					}
				}
			}
		}
		
		return $config;
	}
	
	function Read-MissingIdentifiersFakeData {
		$badData = @{
			ExpectedDisks = @{
				
				BadDisk = @{
					ProvisioningPriority    = 1
					
					VolumeName			    = "D:\"
					VolumeLabel			    = "SQLData"
					
					PhysicalDiskIdentifiers = @{
						# empty on purpose - for testing purposes.
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
		
		return $badData;
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
			Size	    = "200 GB";
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
			Size	    = "120 GB";
			Partitions  = 0;
			DriveLetter = "N/A";
			VolumeId    = "6000c2903aaaac3c851d4eab74af1dbe";
			DeviceId    = "xvnii";
			VolumeName  = "N/A";
			ScsiMapping = "0:1:2:6";
		};
		
		return @($fakeDisk1, $fakeDisk2, $fakeDisk3, $fakeDisk4);
	}
	
	function Find-NonInitializedDisks {
		Read-FakedServerDisks | Where-Object {
			$_.DriveLetter -eq "N/A"
		}; # i.e., 2x non-initialized disks.
	}
	
	function Find-NoNonInitializedDisks {
		return Read-FakedServerDisks | Where-Object {
			$_.Path -eq 'fake path'
		}; # i.e., no matches - or an empty array of disks.
	}
}

Describe "Unit Tests for $functionName" -Tag "UnitTests" {
	
	Context "Input Validation" {
		It "Should Return NULL When There are No Initializable Disks" {
			$config = Read-FakeConfigData;
			$targetIdentifiers = $config.ExpectedDisks.DataDisk.PhysicalDiskIdentifiers;
			
			#$thereAreNoPhysicalDisksToProvision = Find-NoNonInitializedDisks;
			$thereAreNoPhysicalDisksToProvision = @{};  # use an empty hash-table... 
			
			$matches = Find-InitializableDiskByIdentifiers -ExpectedDiskName "DataDisk" -PhysicalDiskIdentifiers $targetIdentifiers -AvailableDisksForInit $thereAreNoPhysicalDisksToProvision;
			
			$matches | Should -BeNull; 
		}
		
		It "Should Throw if Physical Disk Identifiers are NOT supplied" {
			$badData = Read-MissingIdentifiersFakeData;
			$identifiers = $badData.ExpectedDisks.BadDisk.PhysicalDiskIdentifiers;
			
			$availableDisks = Find-NonInitializedDisks;
			
			{
				$matches = Find-InitializableDiskByIdentifiers -ExpectedDiskName "BadDisk" -PhysicalDiskIdentifiers $identifiers -AvailableDisksForInit $availableDisks
			} | Should -Throw;
			
		}
	}
	
	Context "Functional Validation" {
		
		It "Should Return NULL when there are no functional matches" {
			$availableDisks = Find-NonInitializedDisks;
			
			$identifiers = @{
				RawSize	    = "40GB"
				ScsiMapping = "2:0:0:1"
				DiskNumber  = 8
				VolumeId    = "21232323232"
				DeviceId    = "nxvdi"
			};
			
			$matches = $matches = Find-InitializableDiskByIdentifiers -ExpectedDiskName "TempDbDisk" -PhysicalDiskIdentifiers $identifiers -AvailableDisksForInit $availableDisks;
			
			$matches.Count | Should -Be 0;
		}
		
		It "Should Ignore spaces in GB size descriptors" {
			$availableDisks = Find-NonInitializedDisks;
			
			$identifiers = @{
				RawSize	    = "120GB"  # specified HERE at "120GB" - whereas $availableDisks specifies it at "120 GB"
			};
			
			$matches = $matches = Find-InitializableDiskByIdentifiers -ExpectedDiskName "TempDbDisk" -PhysicalDiskIdentifiers $identifiers -AvailableDisksForInit $availableDisks;
			
			$matches.Count | Should -Be 1;
		}
		
		It "Should Return a Single Match When There is a Single Match" {
			$availableDisks = Find-NonInitializedDisks | Where-Object { $_.DiskNumber -eq 5 };
			
			$identifiers = @{
				DiskNumber = 5
			};
			
			$matches = $matches = Find-InitializableDiskByIdentifiers -ExpectedDiskName "TempDbDisk" -PhysicalDiskIdentifiers $identifiers -AvailableDisksForInit $availableDisks;
			
			$matches.Count | Should -Be 1;
		}
		
		It "Should Correctly Match Entire Physical Disk Specification When an Identifer Matches" {
			$availableDisks = Find-NonInitializedDisks | Where-Object {
				$_.DiskNumber -eq 5
			};
			
			$identifiers = @{
				DiskNumber = 5
			};
			
			$matches = $matches = Find-InitializableDiskByIdentifiers -ExpectedDiskName "TempDbDisk" -PhysicalDiskIdentifiers $identifiers -AvailableDisksForInit $availableDisks;
			
			$matches.Count | Should -Be 1;
			$matches.DeviceID | Should -Be "xvnii";
			$matches.ScsiMapping | Should -Be "0:1:2:6";
			$matches.VolumeId | Should -Be "6000c2903aaaac3c851d4eab74af1dbe";
			$matches.Size | Should -Be "120 GB";
			$matches.Path | Should -Be "\\?\scsi#disk&ven_vmware&prod_virtual_disk#5&3862831b&0&000a00#{53f56307-aacc-11d0-94f2-00a0c91efb8b}";
		}
		
		It "Should Mark Matches By Size-Only with SizeMatchOnly Attribute" {
			$availableDisks = Find-NonInitializedDisks | Where-Object {
				$_.DiskNumber -eq 5
			};
			
			$identifiers = @{
				RawSize = "120GB"
			};
			
			$matches = $matches = Find-InitializableDiskByIdentifiers -ExpectedDiskName "TempDbDisk" -PhysicalDiskIdentifiers $identifiers -AvailableDisksForInit $availableDisks;
			
			$matches.Count | Should -Be 1;
			$matches[0].SizeMatchOnly | Should -Be $true;
		}
		
		It "Should Mark Multiple Matches When a Single Disk Has Multiple Matching Identifiers" {
			$availableDisks = Find-NonInitializedDisks | Where-Object {
				$_.DiskNumber -eq 5
			};
			
			$identifiers = @{
				DiskNumber = 5
				DeviceId   = "xvnii"
				ScsiMapping = "0:1:2:6"
			};
			
			$matches = $matches = Find-InitializableDiskByIdentifiers -ExpectedDiskName "TempdbDisk" -PhysicalDiskIdentifiers $identifiers -AvailableDisksForInit $availableDisks;
			
			$matches.Count | Should -Be 1;
			$matches[0].MatchCount | Should -Be 3;
		}
		
		It "Should Return Multiple Disks When Multiple Disks Match a Single Identifier" {
			
			$availableDisks = Find-NonInitializedDisks;
			
			$availableDisks[0].Size = "220GB"; # this is really the ONLY case where duplicates could/should show up, right?
			$availableDisks[1].Size = "220GB";
			
			$identifiers = @{
				RawSize = "220GB"
			};
			
			$matches = $matches = Find-InitializableDiskByIdentifiers -ExpectedDiskName "TempdbDisk" -PhysicalDiskIdentifiers $identifiers -AvailableDisksForInit $availableDisks;
			
			$matches.Count | Should -Be 2;
			$matches[0].SizeMatchOnly | Should -Be $true;
			$matches[1].SizeMatchOnly | Should -Be $true;
			
		}
		
		It "Should Return Multiple Matches with Multiple Physical Identifiers and Matching Disks" {
			$availableDisks = Find-NonInitializedDisks;
			
			$availableDisks[0].Size = "220GB"; # this is really the ONLY case where duplicates could/should show up, right?
			$availableDisks[1].Size = "220GB";
			
			$identifiers = @{
				RawSize = "220GB"
				DiskNumber = 5
				DeviceId   = "xvnii"
			};
			
			$matches = $matches = Find-InitializableDiskByIdentifiers -ExpectedDiskName "TempdbDisk" -PhysicalDiskIdentifiers $identifiers -AvailableDisksForInit $availableDisks;
			
			$matches.Count | Should -Be 2;
			
			$sizeOnly = $matches | Where-Object { $_.DiskNumber -eq 3 };
			$sizeOnly.SizeMatchOnly | Should -Be $true;
			
			$fullMatch = $matches | Where-Object { $_.DiskNumber -eq 5 };
			$fullMatch.SizeMatchOnly | Should -Not -Be $true; # it's not FALSE, it's NULL... hmmm... 
			$fullMatch.MatchCount | Should -Be 3;
		}
		
		# this needs to be moved to Find-UnusedDisksMatchingDefinitions
#		It "Should Rank Higher Match-Counts as Lower-Number Results" {
#			
#		}
	}
	
}

Describe "Integration Tests for $functionName" -Tag "UnitTests" {
	
}