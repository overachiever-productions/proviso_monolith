﻿Set-StrictMode -Version 1.0;

BeforeAll {
	# NOTE: non-standard setup for ProvisoConfig (requires access to defaults as well):
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests\internal", "");
	$sut = Split-Path -Leaf $PSCommandPath.Replace(".Tests.", ".");
	
	. "$root\internal\dsl\$sut";
	. "$root\internal\dsl\ProvisoConfig-Defaults.ps1";
	$script:be8c742fDefaultConfigData = $script:ProvisoConfigDefaults;
}

Describe "Unit Tests for Get-KeyType" -Tags "UnitTests" {
	Context "Static Key Tests" {
		It "Should return Static as Type for Static Host Surface Entry" {
			
			Get-KeyType -Key "Host.TargetServer" | Should -Be "Static";
		}
		
		It "Should return Dynamic for ExpectedDisks Key" {
			
			Get-KeyType -Key "Host.ExpectedDisks.BackupsDisk.VolumeName" | Should -Be "Dynamic";
		}
	}
	
#	Context "Dynamic Key Tests" {
#		
#	}
#	
#	Context "Sql Instance Key Tests" {
#		
#	}
#	
#	Context "Complex Key Tests" {
#		
#	}
}

Describe "Tests for Is-ValidProvisoKey" {
	Context "Static Keys" {
		It "Returns false for invalid Static Keys" {
			# typos/etc.
			Is-ValidProvisoKey -Key "Host.Enabled" | Should -Be $false;
			Is-ValidProvisoKey -Key "SqlServerManagementStuidioiooio.InstallPath" | Should -Be $false;
			Is-ValidProvisoKey -Key "Host.ServerPreferences.SetPowerConfigHigh" | Should -Be $false; # windowsPrefs not ServerPrefs
			Is-ValidProvisoKey -Key "Host.LimitHostTls" | Should -Be $false;
		}
		
		It "Returns true for valid Static Keys" {
			# corrolaries for the above - i.e., correct versions: 
			Is-ValidProvisoKey -Key "Host.TargetServer" | Should -Be $true;
			Is-ValidProvisoKey -Key "SqlServerManagementStudio.InstallPath" | Should -Be $true;
			Is-ValidProvisoKey -Key "Host.WindowsPreferences.SetPowerConfigHigh" | Should -Be $true;
			Is-ValidProvisoKey -Key "Host.LimitHostTls1dot2Only" | Should -Be $true;
		}
		
		It "Doesn't care about Key Case" {
			# same as the 2x different tests above, but with different casings: 
			Is-ValidProvisoKey -Key "host.enabled" | Should -Be $false;
			Is-ValidProvisoKey -Key "sqlserverManagementstuidioiooio.installpath" | Should -Be $false;
			Is-ValidProvisoKey -Key "HOST.ServerPreferences.SETPowerConfigHigh" | Should -Be $false; # windowsPrefs not ServerPrefs
			Is-ValidProvisoKey -Key "Host.LimitHostTLS" | Should -Be $false;
			
			
			Is-ValidProvisoKey -Key "host.targetserver" | Should -Be $true;
			Is-ValidProvisoKey -Key "sqlservermanagementStudio.installpath" | Should -Be $true;
			Is-ValidProvisoKey -Key "HOST.WindowsPreferences.SETPowerConfigHIGH" | Should -Be $true;
			Is-ValidProvisoKey -Key "HOST.LimitHostTls1dot2ONLY" | Should -Be $true;
		}
	}
	
	Context "Dynamic Keys" {
		It "Returns false for invalid Key definitions" {
			Is-ValidProvisoKey -Key "Host.NetworkDefinitions.ProvisioningPriority" | Should -Be $false;
			Is-ValidProvisoKey -Key "Host.ExpectedDisks.ProvisioningPriority" | Should -Be $false;
			
			Is-ValidProvisoKey -Key "ExpectedShares.ShareName" | Should -Be $false;
			
			Is-ValidProvisoKey -Key "DataCollectorSets.Enabled" | Should -Be $false;
			Is-ValidProvisoKey -Key "DataCollectorSets.DaysWorthOfLogsToKeep" | Should -Be $false;
			
		}
		
		It "Returns true for valid key definitions" {
			Is-ValidProvisoKey -Key "Host.NetworkDefinitions.BilboNetwork.ProvisioningPriority" | Should -Be $true;
			Is-ValidProvisoKey -Key "Host.ExpectedDisks.DataDisk.ProvisioningPriority" | Should -Be $true;
			
			Is-ValidProvisoKey -Key "ExpectedShares.SqlBackups.ShareName" | Should -Be $true;
			
			Is-ValidProvisoKey -Key "DataCollectorSets.Consolidated.Enabled" | Should -Be $true;
			Is-ValidProvisoKey -Key "DataCollectorSets.Consolidated.DaysWorthOfLogsToKeep" | Should -Be $true;
			
			Is-ValidProvisoKey -Key "Host.NetworkDefinitions" | Should -Be $true;
			Is-ValidProvisoKey -Key "Host.NetworkDefinitions.VMNetwork" | Should -Be $true;
			Is-ValidProvisoKey -Key "Host.NetworkDefinitions.VMNetwork.AssumableIfNames" | Should -Be $true;
			Is-ValidProvisoKey -Key "Host.NetworkDefinitions.BilboNetwork.IpAddress" | Should -Be $true;
			
			Is-ValidProvisoKey -Key "Host.ExpectedDisks" | Should -Be $true;
			Is-ValidProvisoKey -Key "Host.ExpectedDisks.DataDisk" | Should -Be $true;
			Is-ValidProvisoKey -Key "Host.ExpectedDisks.BackupsDisk" | Should -Be $true;
			Is-ValidProvisoKey -Key "Host.ExpectedDisks.DataDisk.ProvisioningPriority" | Should -Be $true;
			Is-ValidProvisoKey -Key "Host.ExpectedDisks.BackupsDisk.PhysicalDiskIdentifiers" | Should -Be $true;
		}
	}
	
	Context "Implicit Sql Instance Keys - Are all Non-Valid" {
		It "Returns false for Implicit Sql Keys" {
			Is-ValidProvisoKey -Key "ExtendedEvents.BlockedProcesses.SessionName" | Should -Be $false;
			Is-ValidProvisoKey -Key "ExpectedDirectories.RawDirectories" | Should -Be $false;
			Is-ValidProvisoKey -Key "SqlServerInstallation.SqlExePath" | Should -Be $false;
			Is-ValidProvisoKey -Key "SqlServerInstallation.SqlServerDefaultDirectories.SqlDataPath" | Should -Be $false;
			
			Is-ValidProvisoKey -Key "AdminDb.Enabled" | Should -Be $false;
			Is-ValidProvisoKey -Key "AdminDb.Deploy" | Should -Be $false;
		}
	}
	
	Context "Explicit Sql Instance Keys - are viable" {
		It "Returns true for Explicitly Defined Keys"	 {
			
			Is-ValidProvisoKey -Key "AdminDb.MSSQLSERVER.Deploy" | Should -Be $true;
			Is-ValidProvisoKey -Key "AdminDb.X3.Deploy" | Should -Be $true;
			
			Is-ValidProvisoKey -Key "ExpectedDirectories.MSSQLSERVER.RawDirectories" | Should -Be $true;
			Is-ValidProvisoKey -Key "ExpectedDirectories.X3.RawDirectories" | Should -Be $true;
			
			Is-ValidProvisoKey -Key "SqlServerInstallation.MSSQLSERVER.SqlExePath" | Should -Be $true;
			Is-ValidProvisoKey -Key "SqlServerInstallation.X3.SqlServerDefaultDirectories.SqlDataPath" | Should -Be $true;
		}
		
		It "Doesn't care about case for SQL Instance Keys" {
			# some of the same keys from above - but in mixed/different cases: 
			
			Is-ValidProvisoKey -Key "adminDb.mssqlserver.deploy" | Should -Be $true;
			Is-ValidProvisoKey -Key "AdminDb.X3.DEPLOY" | Should -Be $true;
			
			Is-ValidProvisoKey -Key "ExpectedDirectories.MSSQLSERVER.RAWDIRECTORIES" | Should -Be $true;
			Is-ValidProvisoKey -Key "ExpectedDirectories.X3.RAWDIRECTORIES" | Should -Be $true;
			
			Is-ValidProvisoKey -Key "SqlServerInstallation.MSSQLSERVER.SqlExePATH" | Should -Be $true;
			Is-ValidProvisoKey -Key "SqlServerInstallation.X3.SqlServerDefaultDirectories.SqlDataPATh" | Should -Be $true;
		}
	}
	
	#	Context "Complex Keys - Extended Events" {
	#		It "Returns false for Invalid Keys" {
	#			Is-ValidProvisoKey -Key "ExtendedEvents.DisableTelemetry" | Should -Be $false;
	#			
	#			Is-ValidProvisoKey -Key "ExtendedEvents.BlockedProcesses.Enabled" | Should -Be $false;
	#			
	#			Is-ValidProvisoKey -Key "ExtendedEvents.BlockedProcesses.SessionName" | Should -Be $false; 
	#		}
	#		
	#		It "Returns true for valid Keys" {
	#			Is-ValidProvisoKey -Key "ExtendedEvents.MSSQLSERVER" | Should -Be $true;
	#			
	#			Is-ValidProvisoKey -Key "ExtendedEvents.MSSQLSERVER.DisableTelemetry" | Should -Be $true;
	#			Is-ValidProvisoKey -Key "ExtendedEvents.MKC2014.DisableTelemetry" | Should -Be $true;
	#			
	#			Is-ValidProvisoKey -Key "ExtendedEvents.MSSQLSERVER.BlockedProcesses.Enabled" | Should -Be $true;
	#			
	#			Is-ValidProvisoKey -Key "ExtendedEvents.MSSQLSERVER.BlockedProcesses.SessionName" | Should -Be $true;
	#		}
	#		
	#		It "Ignores case for Complex Keys" {
	#			Is-ValidProvisoKey -Key "extendedevents.mssqlserver.blockedprocesses.sessionname" | Should -Be $true;
	#			
	#			
	#		}
	#		
	#	}
	#	
	#	Context "Complex Keys - Availability Groups" {
	#		It "Returns false for invalid Keys" {
	#			
	#		}
	#		
	#		It "Returns True for valid Keys" {
	#			
	#		}
	#	}
}

Describe "Tests for Ensure-ProvisoConfigKeyIsNotImplicit" {
	Context "Non-Sql-Instance Keys are Left Unchanged" {
		It "Leaves Host Keys Alone" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "Host.TargetServer" | Should -Be "Host.TargetServer";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "Host.NetworkDefinitions.VMwareNetwork.IpAddress" | Should -Be "Host.NetworkDefinitions.VMwareNetwork.IpAddress";
			
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "Host.WindowsPreferences" | Should -Be "Host.WindowsPreferences";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "Host.WindowsPreferences.EnableDiskperfCounters" | Should -Be "Host.WindowsPreferences.EnableDiskperfCounters";
			
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "Host.ExpectedDisks" | Should -Be "Host.ExpectedDisks";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "Host.ExpectedDisks.DataDisk" | Should -Be "Host.ExpectedDisks.DataDisk";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "Host.ExpectedDisks.DataDisk.VolumeLabel" | Should -Be "Host.ExpectedDisks.DataDisk.VolumeLabel";
		}
		
		It "Leaves ExpectedShares Alone" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExpectedShares" | Should -Be "ExpectedShares";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExpectedShares.SqlBackups" | Should -Be "ExpectedShares.SqlBackups";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExpectedShares.SqlBackups.ShareName" | Should -Be "ExpectedShares.SqlBackups.ShareName";
		}
		
		It "Leaves Data Collector Sets Alone" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "DataCollectorSets" | Should -Be "DataCollectorSets";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "DataCollectorSets.Consolidated" | Should -Be "DataCollectorSets.Consolidated";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "DataCollectorSets.Consolidated.DaysWorthOfDataToKeep" | Should -Be "DataCollectorSets.Consolidated.DaysWorthOfDataToKeep";
		}
		
		It "Leaves SSMS Keys Alone" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerManagementStudio" | Should -Be "SqlServerManagementStudio";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerManagementStudio.IncludeAzureStudio" | Should -Be "SqlServerManagementStudio.IncludeAzureStudio";
		}
		
		It "Leaves Cluster Configuration Keys Alone" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ClusterConfiguration" | Should -Be "ClusterConfiguration";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ClusterConfiguration.ClusterType" | Should -Be "ClusterConfiguration.ClusterType";
		}
		
		It "Leaves Keys alone Regardless of Case" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "Host.NetworkDefinitions.VMwareNetwork.IPAddreSS" | Should -Be "Host.NetworkDefinitions.VMwareNetwork.IPAddreSS";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExpectedShares.SQLBACKUPS" | Should -Be "ExpectedShares.SQLBACKUPS";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "datacollectorsets.consolidated" | Should -Be "datacollectorsets.consolidated";
		}
	}
	
	Context "Explicit Keys are Not Transformed" {
		It "Does Not Modify Explicit ExpectedDirectories Keys" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExpectedDirectories.MSSQLSERVER" | Should -Be "ExpectedDirectories.MSSQLSERVER";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExpectedDirectories.X3.VirtualSqlServerServiceAccessibleDirectories" | Should -Be "ExpectedDirectories.X3.VirtualSqlServerServiceAccessibleDirectories";
		}
		
		It "Does Not Modify Explicit SqlServer Install or Configuration Keys" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerInstallation.MSSQLSERVER" | Should -Be "SqlServerInstallation.MSSQLSERVER";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerInstallation.MSSQLSERVER.SqlExePath" | Should -Be "SqlServerInstallation.MSSQLSERVER.SqlExePath";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerInstallation.MSSQLSERVER.ServiceAccounts" | Should -Be "SqlServerInstallation.MSSQLSERVER.ServiceAccounts";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerInstallation.TEST2016.ServiceAccounts.SqlServiceAccountName" | Should -Be "SqlServerInstallation.TEST2016.ServiceAccounts.SqlServiceAccountName";
			
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerConfiguration.TEST2016" | Should -Be "SqlServerConfiguration.TEST2016";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerConfiguration.TEST2016.GenerateSPN" | Should -Be "SqlServerConfiguration.TEST2016.GenerateSPN";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerConfiguration.TEST2016.EnabledUserRights" | Should -Be "SqlServerConfiguration.TEST2016.EnabledUserRights";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerConfiguration.TEST2016.EnabledUserRights.LockPagesInMemory" | Should -Be "SqlServerConfiguration.TEST2016.EnabledUserRights.LockPagesInMemory";
			
			# TODO: Enable
			#Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerPatches.MSSQLSERVER" | Should -Be "SqlServerPatches.MSSQLSERVER";
		}
		
		It "Does Not Modify Explicit AdminDb Key" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "AdminDb.MSSQLSERVER" | Should -Be "AdminDb.MSSQLSERVER";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "AdminDb.MSSQLSERVER.Deploy" | Should -Be "AdminDb.MSSQLSERVER.Deploy";
			
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "AdminDb.X3.InstanceSettings" | Should -Be "AdminDb.X3.InstanceSettings";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "AdminDb.X3.InstanceSettings.MAXDOP" | Should -Be "AdminDb.X3.InstanceSettings.MAXDOP";
			
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "AdminDb.MSSQLSERVER.IndexMaintenance" | Should -Be "AdminDb.MSSQLSERVER.IndexMaintenance";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "AdminDb.SS2228.IndexMaintenance.StartTime" | Should -Be "AdminDb.SS2228.IndexMaintenance.StartTime";
		}
		
		It "Does Not Modify Explicit ExtendedEvents Keys" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExtendedEvents.X3" | Should -Be "ExtendedEvents.X3";
			
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExtendedEvents.MSSQLSERVER.DisableTelemetry" | Should -Be "ExtendedEvents.MSSQLSERVER.DisableTelemetry";
			
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExtendedEvents.MSSQLSERVER.BlockedProcesses" | Should -Be "ExtendedEvents.MSSQLSERVER.BlockedProcesses";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExtendedEvents.MSSQLSERVER.BlockedProcesses.Enabled" | Should -Be "ExtendedEvents.MSSQLSERVER.BlockedProcesses.Enabled";
		}
	}
	
	Context "Implicit Keys are Transformed to Explicit Keys" {
		It "Transforms Implicit ExpectedDirectories Keys to Explicit Keys" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExpectedDirectories" | Should -Be "ExpectedDirectories.{~SQLINSTANCE~}";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExpectedDirectories.VirtualSqlServerServiceAccessibleDirectories" | Should -Be "ExpectedDirectories.{~SQLINSTANCE~}.VirtualSqlServerServiceAccessibleDirectories";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExpectedDirectories.RawDirectories" | Should -Be "ExpectedDirectories.{~SQLINSTANCE~}.RawDirectories";
		}
		
		It "Transforms Implicit SqlInstall and Config Keys to Explicit Keys" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerInstallation" | Should -Be "SqlServerInstallation.{~SQLINSTANCE~}";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerInstallation.SqlExePath" | Should -Be "SqlServerInstallation.{~SQLINSTANCE~}.SqlExePath";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerInstallation.Setup" | Should -Be "SqlServerInstallation.{~SQLINSTANCE~}.Setup";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerInstallation.Setup.InstallDirectory" | Should -Be "SqlServerInstallation.{~SQLINSTANCE~}.Setup.InstallDirectory";
			
			
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerConfiguration" | Should -Be "SqlServerConfiguration.{~SQLINSTANCE~}";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerConfiguration.EnabledUserRights" | Should -Be "SqlServerConfiguration.{~SQLINSTANCE~}.EnabledUserRights";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerConfiguration.EnabledUserRights.LockPagesInMemory" | Should -Be "SqlServerConfiguration.{~SQLINSTANCE~}.EnabledUserRights.LockPagesInMemory";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerConfiguration.TraceFlags" | Should -Be "SqlServerConfiguration.{~SQLINSTANCE~}.TraceFlags";
			
			# TODO: Enable
			#Ensure-ProvisoConfigKeyIsNotImplicit -Key "SqlServerPatches" | Should -Be "SqlServerPatches.{~SQLINSTANCE~}";
		}
		
		It "Transforms Implicit AdminDb Keys to Explicit Keys" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "AdminDb.Deploy" | Should -Be "AdminDb.{~SQLINSTANCE~}.Deploy";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "AdminDb.InstanceSettings" | Should -Be "AdminDb.{~SQLINSTANCE~}.InstanceSettings";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "AdminDb.InstanceSettings.MAXDOP" | Should -Be "AdminDb.{~SQLINSTANCE~}.InstanceSettings.MAXDOP";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "AdminDb.Alerts" | Should -Be "AdminDb.{~SQLINSTANCE~}.Alerts";
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "AdminDb.Alerts.IOAlertsFiltered" | Should -Be "AdminDb.{~SQLINSTANCE~}.Alerts.IOAlertsFiltered";
		}
		
		It "Transforms Implicit ExtendedEvents Keys to Explicit Keys" {
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExtendedEvents" | Should -Be "ExtendedEvents.{~SQLINSTANCE~}";
			
			Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExtendedEvents.DisableTelemetry" | Should -Be "ExtendedEvents.{~SQLINSTANCE~}.DisableTelemetry";
			
			# TODO: barf... these are really complex/ugly... 
			#Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExtendedEvents.CorrelatedSpills" | Should -Be "ExtendedEvents.{~SQLINSTANCE~}.CorrelatedSpills";
			#Ensure-ProvisoConfigKeyIsNotImplicit -Key "ExtendedEvents.CorrelatedSpills.SessionName" | Should -Be "ExtendedEvents.{~SQLINSTANCE~}.CorrelatedSpills.SessionName";
		}
	}
}

Describe "Tests for Get-FacetTypeByKey" {
	Context "Host Keys" {
		It "Identifies Scalar Host Keys as Simple" {
			Get-FacetTypeByKey -Key "Host.TargetDomain" | Should -Be "Simple";
			Get-FacetTypeByKey -Key "Host.WindowsPreferences.OptimizeExplorer" | Should -Be "Simple";
			Get-FacetTypeByKey -Key "Host.FirewallRules.EnableICMP" | Should -Be "Simple";
			Get-FacetTypeByKey -Key "Host.AllowGlobalDefaults" | Should -Be "Simple";
		}
		
		It "Identifies Array Host Keys as SimpleArray" {
			Get-FacetTypeByKey -Key "Host.LocalAdministrators" | Should -Be "SimpleArray";
		}
		
		It "Identifies Disks and NICs as Object" {
			Get-FacetTypeByKey -Key "Host.NetworkDefinitions" | Should -Be "Object";
			Get-FacetTypeByKey -Key "Host.NetworkDefinitions.Eth0" | Should -Be "Object";
			Get-FacetTypeByKey -Key "Host.NetworkDefinitions.Eth0.InterfaceAlias" | Should -Be "Object";
			Get-FacetTypeByKey -Key "Host.NetworkDefinitions.VMNetwork.IpAddress" | Should -Be "Object";
		}
		
		It "Identifies AssumableIfs as ObjectArray" {
			Get-FacetTypeByKey -Key "Host.NetworkDefinitions.VMNetwork.AssumableIfNames" | Should -Be "ObjectArray";
		}
	}
	
	Context "SqlServerManagementStudio" {
		It "Identifies SSMS Keys as Simple" {
			Get-FacetTypeByKey -Key "SqlServerManagementStudio" | Should -Be "Simple";
			Get-FacetTypeByKey -Key "SqlServerManagementStudio.Binary" | Should -Be "Simple";
			Get-FacetTypeByKey -Key "SqlServerManagementStudio.IncludeAzureStudio" | Should -Be "Simple";
		}
	}
	
	Context "Object Keys" {
		It "Identifies ExpectedShares as Object" {
			Get-FacetTypeByKey -Key "ExpectedShares.SqlBackups" | Should -Be "Object";
			Get-FacetTypeByKey -Key "ExpectedShares.SqlBackups.ShareName" | Should -Be "Object";
		}
		
		It "Identifies ExpectedShares Arrays as ObjectArray" {
			Get-FacetTypeByKey -Key "ExpectedShares.SqlBackups.ReadOnlyAccess" | Should -Be "ObjectArray";
			Get-FacetTypeByKey -Key "ExpectedShares.SqlBackups.ReadWriteAccess" | Should -Be "ObjectArray";
		}
		
		It "Identifies DataCollectorSets as Object" {
			Get-FacetTypeByKey -Key "DataCollectorSets" | Should -Be "Object";
			Get-FacetTypeByKey -Key "DataCollectorSets.Consolidated" | Should -Be "Object";
			Get-FacetTypeByKey -Key "DataCollectorSets.Mirroring.EnableStartWithOS" | Should -Be "Object";
		}
	}
	
	Context "SqlObject Keys" {
		It "Identifies SqlObject Roots" {
			Get-FacetTypeByKey -Key "ExpectedDirectories" | Should -Be "SqlObject";
			Get-FacetTypeByKey -Key "SqlServerInstallation" | Should -Be "SqlObject";
			Get-FacetTypeByKey -Key "SqlServerConfiguration" | Should -Be "SqlObject";
			
			# TODO:
			#Get-FacetTypeByKey -Key "SqlServerPatches" | Should -Be "SqlObject";
			Get-FacetTypeByKey -Key "AdminDb" | Should -Be "SqlObject";
		}
		
		It "Identifies SqlObject Scalars as SqlObject" {
			Get-FacetTypeByKey -Key "SqlServerInstallation.MSSQLSERVER.SqlExePath" | Should -Be "SqlObject";
			Get-FacetTypeByKey -Key "SqlServerInstallation.MSSQLSERVER.Setup" | Should -Be "SqlObject";
			Get-FacetTypeByKey -Key "SqlServerInstallation.MSSQLSERVER.Setup.InstantFileInit" | Should -Be "SqlObject";
		}
		
		It "Identifies ExpectedDirectoris Children as SqlObjectArray" {
			Get-FacetTypeByKey -Key "ExpectedDirectories.MSSQLSERVER.VirtualSqlServerServiceAccessibleDirectories" | Should -Be "SqlObjectArray";
			Get-FacetTypeByKey -Key "ExpectedDirectories.MSSQLSERVER.RawDirectories" | Should -Be "SqlObjectArray";
		}
		
		It "Identifies MembersOfSysAdmin as SqlObjectArray" {
			Get-FacetTypeByKey -Key "SqlServerInstallation.X7.SecuritySetup.MembersOfSysAdmin" | Should -Be "SqlObjectArray";
		}
		
		It "Identifies TraceFlags as SqlObjectArray" {
			# verify that something in the same 'surface' is correctly identified first:
			Get-FacetTypeByKey -Key "SqlServerConfiguration.MSSQLSERVER.DisableSaLogin" | Should -Be "SqlObject";
			
			Get-FacetTypeByKey -Key "SqlServerConfiguration.MSSQLSERVER.TraceFlags" | Should -Be "SqlObjectArray";
		}
	}
	
	Context "CompoundKeys" {
		It "Identifies Compound Key Roots" {
			Get-FacetTypeByKey -Key "ExtendedEvents" | Should -Be "Compound";
			
			# TODO:
			#Get-FacetTypeByKey -Key "ResourceGovernor" | Should -Be "Compound";
			#Get-FacetTypeByKey -Key "AvailabilityGroups" | Should -Be "Compound";
			#Get-FacetTypeByKey -Key "CustomSqlScripts" | Should -Be "Compound";
		}
		
		It "Detects SqlObject-Only/Global Keys" {
			Get-FacetTypeByKey -Key "ExtendedEvents.DisableTelemetry" | Should -Be "Compound";  # Implicit
			Get-FacetTypeByKey -Key "ExtendedEvents.MSSQLSERVER.DisableTelemetry" | Should -Be "Compound"; # Explicit
		}
		
		It "Converts Implicit SqlInstances to Compound Keys" {
			Get-FacetTypeByKey -Key "ExtendedEvents.DisableTelemetry" | Should -Be "Compound";
			
			Get-FacetTypeByKey -Key "ExtendedEvents.BlockedProcesses" | Should -Be "Compound";
		}
		
		It "Throws On Implicit Compound Key Requests" {
			{ Get-FacetTypeByKey -Key "ExtendedEvents.BlockedProcesses.SessionName" } | Should -Throw;
		}
		
		It "Reports Object Children as Compound" {
			Get-FacetTypeByKey -Key "ExtendedEvents.X3.BlockedProcesses.SessionName" | Should -Be "Compound";
		}
	}
}