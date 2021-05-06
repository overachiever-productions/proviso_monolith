#. ..\functions\Confirm-Directories.ps1

# Sample Invocation: > 

BeforeAll {
	
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "\functions");
	$sut = Split-Path -Leaf $PSCommandPath.Replace(".Tests.", ".");
	$functionName = $sut.Replace(".ps1", "");
	
	. "$root\$sut";
	
	function Read-FakeDefinition {
		$config = @{
			TargetServer  = "SQL-105-A"
			
			ExpectedDirectories = @{
				VirtualSqlServerServiceAccessibleDirectories = @(
					"D:\SQLData"
					"D:\SQLBackups"
				)
				
			RawDirectories  = @(
					"E:\Archived"
					"E:\Traces"
				)
			}
		}
		
		return $config;
	}
	
	#region Fakes 
	function Get-InstalledSqlServerInstanceNames {
		return @();
	}
	
	function Mount-Directory($Path) {
		return "";
	}
	
	function Grant-SqlServicePermissionsToDirectory {
		param (
			[string]$TargetDirectory,
			[string]$SqlServiceAccountName
		);
		
		return "";
	}
	#endregion
	
}

Describe "Unit Tests for $functionName" -Tag "UnitTests" {
	Context "Input Validation" {
		It "Should Not Throw when Strict enabled and HostName matches ConfigName" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$config.TargetServer = $env:COMPUTERNAME;
			
			# fake SQL Server installation details:
			Mock Get-InstalledSqlServerInstanceNames {
				return @();
			};
			
			Confirm-Directories -ServerDefinition $config -Strict;
		}
		
		It "Should Throw when Strict enabled and HostName does not match ConfigName" {
			[PSCustomObject]$config = Read-FakeDefinition;
			
			# fake SQL Server installation details:
			Mock Get-InstalledSqlServerInstanceNames {
				return @();
			};
			
			{
				Confirm-Directories -ServerDefinition $config -Strict;
			} | Should -Throw;
		}
	}
	
	Context "Dependency Validation" {
		It "Should Call Get-InstalledSqlServerInstanceNames to determine if SQL Server is Installed" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$config.TargetServer = $env:COMPUTERNAME;
			
			# fake SQL Server installation details:
			Mock Get-InstalledSqlServerInstanceNames {
				return @();
			};
			
			Confirm-Directories -ServerDefinition $config -Strict;
			
			Should -Invoke Get-InstalledSqlServerInstanceNames -Times 1 -Exactly;
		}
		
		It "Should Call Mount-Directory for Configured Raw Directories" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$config.TargetServer = $env:COMPUTERNAME;
			
			# fake SQL Server installation details:
			Mock Get-InstalledSqlServerInstanceNames {
				return @();
			};
			
			Mock Mount-Directory {
				return "";
			} -ParameterFilter {
				($Path -eq "E:\Archived") -or ($Path -eq "E:\Traces");
			}
			
			Confirm-Directories -ServerDefinition $config -Strict;
			
			Should -Invoke Mount-Directory -Times 2 -Exactly;
		}
		
		It "Should Call Mount-Directory to Create VirtualSQLServerAccessible Directories" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$config.TargetServer = $env:COMPUTERNAME;
			
			# fake SQL Server installation details:
			Mock Get-InstalledSqlServerInstanceNames {
				return @();
			};
			
			Mock Mount-Directory {
				return "";
			} -ParameterFilter {
				$Path.StartsWith("D:\");
			}
			
			Confirm-Directories -ServerDefinition $config -Strict;
			
			Should -Invoke Mount-Directory -Times 2 -Exactly;
		}
		
		It "Should Call Grant-ServicePermissionsToDirectory when SQL Server is Installed" {
			[PSCustomObject]$config = Read-FakeDefinition;
			$config.TargetServer = $env:COMPUTERNAME;
			
			# fake SQL Server installation details:
			Mock Get-InstalledSqlServerInstanceNames {
				return @(
					"MSSQLSERVER"	
				);
			};
			
			Mock Grant-SqlServicePermissionsToDirectory {
				return "";
			} -ParameterFilter {
				$SqlServiceAccountName -eq "NT SERVICE\MSSQLSERVER";
			}
			
			Confirm-Directories -ServerDefinition $config -Strict;
			
			Should -Invoke Grant-SqlServicePermissionsToDirectory -Times 2 -Exactly;
		}
		
	}
	
	Context "Functional Validation" {
		# No real functional validation - i.e., Confirm-Directories really just acts as a 'controller' - by processing logic and issuing calls to various other funcs/dependencies.
	}
}