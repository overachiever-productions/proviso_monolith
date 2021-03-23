#. ..\functions\Confirm-Shares.ps1

# Sample Invocation: > 

BeforeAll {
	
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "\functions");
	$sut = Split-Path -Leaf $PSCommandPath.Replace(".Tests.", ".");
	$functionName = $sut.Replace(".ps1", "");
	
	. "$root\$sut";
	
	function Read-FakeDefinition {
		$config = @{
			TargetServer	    = "SQL-105-A"
			
			ExpectedShares	    = @{
				SqlBackups = @{
					SourceDirectory = "E:\SQLBackups"
					ShareName	    = "SQLBackups"
					ReadOnlyAccess  = @(
						"aws\`$sql2_service"
					)
					ReadWriteAccess = @(
						"Administrators"
					)
				}
			}
		}
		
		return $config;
	}
	
	#region Fakes
	function Mount-Directory($Path) {
		return "";
	}
	
	function Grant-SmbShareAccess($Name, $AccountName, $AccessRight) {
		# this overwrites built-in functionality (obviously) so that we can test reads or full access - without throwing the whole "can't find an MS SMB share with name x" error and so on... 
		#   i.e., if I set up a mock for a set of params to test/validate - that's great. but what about the OTHER 'call'? that won't 'match' and will go to the real/original func (doh)
		return "";
	}
	
	#endregion
	
}

Describe "Unit Tests for $functionName" -Tag "UnitTests" {
	Context "Input Validation" {
		
		It "Should Throw when Strict enabled and HostName does not match ConfigName" {
			[PSCustomObject]$config = Read-FakeDefinition;
			
			{
				Confirm-Shares -ServerDefinition $config -Strict;
			} | Should -Throw;
		}
		
		It "Should Not Throw when Strict enabled and HostName matches ConfigName" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$config.TargetServer = $env:COMPUTERNAME;
			
			Mock Get-SmbShare {
				return $null;
			}
			
			Mock New-SmbShare {
				
			};
			
			Mock Grant-SmbShareAccess {
				
			};
			
			Confirm-Shares -ServerDefinition $config -Strict;
		}
	}
	
	Context "Dependency Validation"	 {
		It "Should Call Mount-Volume for each share directory enumerated" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$config.TargetServer = $env:COMPUTERNAME;
			
			Mock Mount-Directory {
			} -ParameterFilter {
				$Path -eq "E:\SQLBackups";
			}
			
			Mock Get-SmbShare {
				return $null;
			}
			
			Mock New-SmbShare {
			};
			
			Mock Grant-SmbShareAccess {
			};
			
			Confirm-Shares -ServerDefinition $config -Strict;
			
			Should -Invoke Mount-Directory -Times 1 -Exactly;
		}
	}
	
	Context "Functional Validation" {
		It "Should Call Get-SmbShare to see if Share Exists" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$config.TargetServer = $env:COMPUTERNAME;
			
			Mock Get-SmbShare {
				return $null;
			} -ParameterFilter {
				$Name -eq "SQLBackups"
			}
			
			Mock New-SmbShare {
			};
			
			Mock Grant-SmbShareAccess {
			};
			
			Confirm-Shares -ServerDefinition $config -Strict;
			
			Should -Invoke Get-SmbShare -Times 1 -Exactly;
		}
		
		It "Should Call New-SmbShare to create a new share if target share does not exist" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$config.TargetServer = $env:COMPUTERNAME;
			
			Mock Get-SmbShare {
				return $null;
			};
			
			Mock New-SmbShare {
			} -ParameterFilter {
				$Name -eq "SQLBackups" -and $Path -eq "E:\SQLBackups"
			};
			
			Mock Grant-SmbShareAccess {
			};
			
			Confirm-Shares -ServerDefinition $config -Strict;
			
			Should -Invoke New-SmbShare -Times 1 -Exactly;
		}
				
		It "Should Call Grant-SmbShareAccess for each account allowed Read Access" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$config.TargetServer = $env:COMPUTERNAME;
			
			Mock Get-SmbShare {
				return $null;
			};
			
			Mock New-SmbShare {
			}
			
			Mock Grant-SmbShareAccess {
				return $null
			} -ParameterFilter {
				$AccountName -eq "aws\`$sql2_service" -and $AccessRight -eq "Read"
			}
			
			Confirm-Shares -ServerDefinition $config -Strict;
			
			Should -Invoke Grant-SmbShareAccess -Times 1 -Exactly;
		}
		
		It "Should Call Grant-SmbShareAccess for each account allowed Full Access" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$config.TargetServer = $env:COMPUTERNAME;
			
			Mock Get-SmbShare {
				return $null;
			};
			
			Mock New-SmbShare {
			}
			
			Mock Grant-SmbShareAccess {
				return $null
			} -ParameterFilter {
				$AccountName -eq "Administrators" -and $AccessRight -eq "Full"
			}
			
			Confirm-Shares -ServerDefinition $config -Strict;
			
			Should -Invoke Grant-SmbShareAccess -Times 1 -Exactly;
		}
	}
}