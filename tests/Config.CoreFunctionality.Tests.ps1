Set-StrictMode -Version 1.0;


BeforeAll {
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "");
	
	. "$root\internal\dsl\ProvisoConfig.ps1";
	. "$root\internal\dsl\ProvisoConfig-Defaults.ps1";
	$script:be8c742fDefaultConfigData = $script:ProvisoConfigDefaults;
}

Describe "AllowableChildKeyNames - Tests " {
	Context "Error Conditions" {
		It "Returns NOTHING for Invalid Root Keys" {
			(Get-AllowableChildKeyNames -Key "ClownCar").Count | Should -Be 0;
		}
		
		It "Returns NOTHING for Invalid Child Keys" {
			(Get-AllowableChildKeyNames -Key "DataCollectorSets.X3.SandwichTypes").Count | Should -Be 0;
		}
	}
	
	Context "Tokenization Required Tests" {
		It "Returns NOTHING for hard-coded SQL Server Instance Keys" {
			(Get-AllowableChildKeyNames -Key "ClusterConfiguration.MSSQLSERVER.ClusterName").Count | Should -Be 0;
		}
		
		It "Returns NOTHING for hard-coded Object Instance Keys" {
			(Get-AllowableChildKeyNames -Key "ClusterConfiguration.MSSQLSERVER.ClusterName").Count | Should -Be 0;
		}
		
		It "Returns NOTHING for non-Tokenized Sql-And-Object Keys" {
			(Get-AllowableChildKeyNames -Key "AvailabilityGroups.TESTSQL.Groups.MyAG.Listener").Count | Should -Be 0;
		}
		
		It "Returns Child-keys for Sql-Instance-Tokenized Keys" {
			(Get-AllowableChildKeyNames -Key "AdminDb.{~SQLINSTANCE~}.DatabaseMail").Count | Should -BeGreaterThan 8;
			
			((Get-AllowableChildKeyNames -Key "AdminDb.{~SQLINSTANCE~}.DatabaseMail") -contains "OperatorEmail") | Should -Be $true;
			((Get-AllowableChildKeyNames -Key "AdminDb.{~SQLINSTANCE~}.DatabaseMail") -contains "SmptUserName") | Should -Be $true;
		}
		
		It "Returns Child-keys for Object-Instance-Tokenized Keys" {
			(Get-AllowableChildKeyNames -Key "DataCollectorSets.{~ANY~}").Count | Should -BeGreaterThan 3;
			
			((Get-AllowableChildKeyNames -Key "DataCollectorSets.{~ANY~}") -contains "XmlDefinition") | Should -Be $true;
			((Get-AllowableChildKeyNames -Key "DataCollectorSets.{~ANY~}") -contains "DaysWorthOfLogsToKeep") | Should -Be $true;
		}
		
		It "Returns Child-Keys for Sql-and-Object-Tokenized Keys" {
			(Get-AllowableChildKeyNames -Key "AvailabilityGroups.{~SQLINSTANCE~}.Groups.{~ANY~}.Listener").Count | Should -BeGreaterThan 3;
			
			((Get-AllowableChildKeyNames -Key "AvailabilityGroups.{~SQLINSTANCE~}.Groups.{~ANY~}.Listener") -contains "PortNumber") | Should -Be $true;
		}
	}
	
	Context "Legitimate Keys" {
		It "Returns Root Level Keys When No Value Specified" {
			(Get-AllowableChildKeyNames).Count | Should -BeGreaterThan 12;
			
			((Get-AllowableChildKeyNames) -contains "Host") | Should -Be $true;
			((Get-AllowableChildKeyNames) -contains "ExpectedShares") | Should -Be $true;
			((Get-AllowableChildKeyNames) -contains "AdminDb") | Should -Be $true;
			((Get-AllowableChildKeyNames) -contains "DataCollectorSets") | Should -Be $true;
		}
		
		It "Returns Level 1 Keys When a Root is Specified " {
			(Get-AllowableChildKeyNames -Key "Host").Count | Should -BeGreaterThan 10;
			
			((Get-AllowableChildKeyNames -Key "Host") -contains "TargetServer") | Should -Be $true;
			((Get-AllowableChildKeyNames -Key "Host") -contains "Compute") | Should -Be $true;
			((Get-AllowableChildKeyNames -Key "Host") -contains "NetworkDefinitions") | Should -Be $true;
			((Get-AllowableChildKeyNames -Key "Host") -contains "FirewallRules") | Should -Be $true;
		}
		
		It "Returns Level 2 Keys when a Level1 Key is Specified" {
			(Get-AllowableChildKeyNames -Key "SqlServerInstallation.{~SQLINSTANCE~}").Count | Should -BeGreaterThan 4;
			
			((Get-AllowableChildKeyNames -Key "SqlServerInstallation.{~SQLINSTANCE~}") -contains "SqlExePath") | Should -Be $true;
			((Get-AllowableChildKeyNames -Key "SqlServerInstallation.{~SQLINSTANCE~}") -contains "ServiceAccounts") | Should -Be $true;
			((Get-AllowableChildKeyNames -Key "SqlServerInstallation.{~SQLINSTANCE~}") -contains "SecuritySetup") | Should -Be $true;
		}
	}
}