#. "..\functions\Read-ServerDefinitions.ps1";

BeforeAll {
	
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "\functions");
	$sut = Split-Path -Leaf $PSCommandPath.Replace(".Tests.", ".");
	$functionName = $sut.Replace(".ps1", "");
	
	. "$root\$sut";
	
	function Read-FakeData1 {
		$data = @{
			
			TargetServer = "AWS-SQL-1B"
			
			HostName	 = @{
				DomainName  = "aws.local"
				MachineName = "AWS-SQL-1B"
			}
		};
		
		return $data;
	}
	
	function Read-FakeDataWithCurrentHostName {
		$data = @{
			TargetServer = "$($env:COMPUTERNAME)"
		};
		
		return $data;
	}
	
}

Describe "Unit Tests for $functionName" -Tag "UnitTests" {
	Context "Parameter Validation" {
		$fakeDirectory = "N:\InvalidPath\host-name.ps1d";
		
		It "Should Throw if -Path is invalid" {
			{ Read-ServerDefinitions -Path $fakeDirectory } | Should -Throw;
		}
		
	}
	
	Context "Functional Validation" {
		It "Should Throw When Strict and Host Does Not Match" {
			Mock Import-PowerShellDataFile {
				return Read-FakeData1;
			};
			
			{ Read-ServerDefinitions -Path $root\$sut -Strict:$true } | Should -Throw;
		}
		
		It "Should Not Throw When Strict and Host Does Match" {
			Mock Import-PowerShellDataFile {
				return Read-FakeDataWithCurrentHostName;
			};
			
			{ Read-ServerDefinitions -Path $root\$sut -Strict:$true } | Should -Not -Throw;
		}
				
		It "Should Represent Underlying Serialized Data" {
			Mock Import-PowerShellDataFile {
				return Read-FakeData1;
			};
			
			$output = Read-ServerDefinitions -Path $root\$sut -Strict:$false;
			$output.HostName.DomainName | Should -Be "aws.local";
		}
	}
}

Describe "Integration Tests for $functionName" -Tag "UnitTests" {
	
	
	
	
}
