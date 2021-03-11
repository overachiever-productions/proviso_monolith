#. "..\functions\Find-NonInitializedDisks.ps1";

BeforeAll {
	
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "\functions");
	$sut = Split-Path -Leaf $PSCommandPath.Replace(".Tests.", ".");
	$functionName = $sut.Replace(".ps1", "");
	
	. "$root\$sut";
	
	function Fake-Disks {
		
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
	
	function Get-DiskDetails {
		return Fake-Disks;
	}
	
}

Describe "Unit Tests for $functionName" -Tag "UnitTests" {
	
	Context "Dependency Validation" {
		
		It "Should Get Disk Info from Get-DiskDetails" {
			Mock Get-DiskDetails {
				return Fake-Disks;
			}
			
			$results = Find-NonInitializedDisks;
			Assert-MockCalled -CommandName Get-DiskDetails -Times 1;
		}
		
	}
	
	Context "Functional Validation" {
		It "Should Exclude Disks with Existing Volumes" {
			Mock Get-DiskDetails {
				return Fake-Disks;
			}
			
			$results = Find-NonInitializedDisks;
			$results.Count | Should -BeExactly 2;
			foreach ($disk in $results) {
				$disk.DriveLetter | Should -Not -Be "D";
				$disk.DriveLetter | Should -Not -Be "E";
			}
		}
		
		It "Should Only Return Disks Without Volumes Defined" {
			Mock Get-DiskDetails {
				return Fake-Disks;
			}
			
			$results = Find-NonInitializedDisks;
			$results.Count | Should -BeExactly 2;
			foreach ($disk in $results) {
				$disk.DriveLetter | Should -BeExactly "N/A";
			}
		}
	}
	
}

Describe "Integration Tests for $functionName" -Tag "UnitTests" {
	
}