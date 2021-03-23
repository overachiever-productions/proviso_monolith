#. ..\functions\Initialize-DefinedDisks.ps1

BeforeAll {
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "\functions");
	$sut = Split-Path -Leaf $PSCommandPath.Replace(".Tests.", ".");
	$functionName = $sut.Replace(".ps1", "");
	
	. "$root\$sut";
	
	function Read-FakeDefinition {
		$config = @{
			TargetServer = "SQL-105-A"
			
			ExpectedDisks = @{
				
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
	
	function Get-FakedMountedVolumes {
		Read-FakedServerDisks | Where-Object {
			$_.DriveLetter -eq "N/A"
		}; # i.e., 2x non-initialized disks.
	}
	
	#region Fakes 
	function Get-UnconfiguredDisks {
		return @{
		};
	}
	
	function Initialize-TargetedDisk {
		return "";
	}
	#endregion
}

Describe "Unit Tests for $functionName" -Tag "UnitTests" {
	Context "Input Validation" {
		It "Should Throw when Strict enabled and HostName does not match ConfigName" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$mountedVolumes = Get-FakedMountedVolumes;
			
			# not going to bother faking the current host name - i.e., just 'assume' it's different than the host-name specified:
			{
				Initialize-DefinedDisks -ServerDefinition $config -CurrentlyMountedVolumes $mountedVolumes -Strict;
			} | Should -Throw;
		}
	}
	
	Context "Dependency Validation" {
		It "Should Call Get-UnconfiguredDisks to enumerate disks to potentially process" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$mountedVolumes = Get-FakedMountedVolumes;
			
			Mock Get-UnconfiguredDisks {
				$output = @{};
				
				return $output;
			}
			
			# test in non -Strict: 
			Initialize-DefinedDisks -ServerDefinition $config -CurrentlyMountedVolumes $mountedVolumes -Strict:$false;
			
			Should -Invoke Get-UnconfiguredDisks -Times 1 -Exactly;
		}
		
		It "Should call Initialize-TargetDisk when it finds a disk to initialize" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$mountedVolumes = Get-FakedMountedVolumes;
			
			Mock Get-UnconfiguredDisks {
				$output = @{};
				
				$mockedPhysicalDisk = @{
					DiskNumber = 999
				};
				
				$output["TempDisk2"] = @{
					
					NameOfExpectedDisk   = "TempDisk2"
					ProvisioningPriority = 7
					MatchFound		     = $true
					
					MatchedPhysicalDisk  = $mockedPhysicalDisk
				};
				
				return $output;
			}
			
			Mock Initialize-TargetedDisk {
				return "";
			} -Verifiable -ParameterFilter {
				$DiskNumber -eq 999;
			}
			
			# test in non -Strict: 
			Initialize-DefinedDisks -ServerDefinition $config -CurrentlyMountedVolumes $mountedVolumes -Strict:$false;
			
			# NOTE: this test validates that we're initializing the physical disk 'passed in' to Initialize-TargetedDisk (i.e., the disk with a Physical DiskNumber of 999).
			Should -Invoke Initialize-TargetedDisk -Times 1 -Exactly;
		}
	}
	
	Context "Functional Validation" {
		It "Should Throw when Strict enabled and no available disk is found for an expected disk" {
			[PSCustomObject]$config = Read-FakeDefinition;
			
			# sigh, stupid 'strict' testing: 
			$config.TargetServer = $env:COMPUTERNAME;
			
			$mountedVolumes = Get-FakedMountedVolumes;
			
			Mock Get-UnconfiguredDisks {
				$output = @{
				};
				
				$mockedPhysicalDisk = @{
					DiskNumber = 999
				};
				
				$output["TempDisk2"] = @{
					
					NameOfExpectedDisk   = "TempDisk2"
					ProvisioningPriority = 7
					MatchFound		     = $false # doh... no match found... 
					
					MatchedPhysicalDisk  = $mockedPhysicalDisk
				};
				
				return $output;
			}
			
			{
				Initialize-DefinedDisks -ServerDefinition $config -CurrentlyMountedVolumes $mountedVolumes;
			} | Should -Throw -ExpectedMessage "*no matches available*"
			
		}
	}
}