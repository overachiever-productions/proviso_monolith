Set-StrictMode -Version 1.0;

BeforeAll {
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "");
	
	. "$root\proviso.meta.ps1";
	Import-ProvisoTypes -ScriptRoot $root;
	
	. "$root\internal\dsl\ProvisoConfig.ps1";
	. "$root\internal\dsl\ProvisoConfig-Defaults.ps1";
	$script:be8c742fDefaultConfigData = $script:ProvisoConfigDefaults;
}


Describe "Key-Validation Tests" {
	Context "Invalid Key Tests" {
		
		It "Returns false for Invalid Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerSmurfVillage").IsValid | Should -Be $false;
		}
	}
	
	Context "Root Keys" {
		It "Detects Invalid Roots" {
			(Validate-ConfigurationEntry -Key "ExpectedFolders").IsValid | Should -Be $false;
			(Validate-ConfigurationEntry -Key "AdminDatabase").IsValid | Should -Be $false;
		}
		
		It "Return true for legit Root Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerInstallation").IsValid | Should -Be $true;
			
			(Validate-ConfigurationEntry -Key "ExtendedEvents").IsValid | Should -Be $true;
		}
	}
	
	Context "Host Values" {
		
		It "Detects Invalid Keys" {
			(Validate-ConfigurationEntry -Key "Host.ServerName").IsValid | Should -Be $false;
			(Validate-ConfigurationEntry -Key "Host.DomainName").IsValid | Should -Be $false;
			
			
			(Validate-ConfigurationEntry -Key "Host.CoreCount").IsValid | Should -Be $false;
			(Validate-ConfigurationEntry -Key "Host.OptimizeExplorer").IsValid | Should -Be $false;
			(Validate-ConfigurationEntry -Key "Host.EnableFirewallForSqlServer").IsValid | Should -Be $false;
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "Host.TargetServer").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "Host.TargetDomain").IsValid | Should -Be $true;
			
			(Validate-ConfigurationEntry -Key "Host.LocalAdministrators").IsValid | Should -Be $true;
			
			(Validate-ConfigurationEntry -Key "Host.Compute.NumaNodes").IsValid | Should -Be $true;
			
			(Validate-ConfigurationEntry -Key "Host.WindowsPreferences").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "Host.WindowsPreferences.DisableMonitorTimeout").IsValid | Should -Be $true;
			
			(Validate-ConfigurationEntry -Key "Host.FirewallRules").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "Host.FirewallRules.EnableICMP").IsValid | Should -Be $true;
		}
	}
	
	Context "Host Adapters" {
		It "Detects Invalid Keys" {
			(Validate-ConfigurationEntry -Key "Host.NetworkAdapters").IsValid | Should -Be $false;
			(Validate-ConfigurationEntry -Key "Host.InterfaceAlias").IsValid | Should -Be $false;
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "Host.NetworkDefinitions.VMNetwork").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "Host.NetworkDefinitions.Eth0").IsValid | Should -Be $true;
			
			(Validate-ConfigurationEntry -Key "Host.NetworkDefinitions.Ethernet3.ProvisioningPriority").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "Host.NetworkDefinitions.Ethernet3.Gateway").IsValid | Should -Be $true;
		}
		
		It "Extracts Object Names" {
			(Validate-ConfigurationEntry -Key "Host.NetworkDefinitions.Ethernet3.Gateway").ObjectInstanceName | Should -Be "Ethernet3";
		}
		
		It "Tokenizes Adapter Names" {
			(Validate-ConfigurationEntry -Key "Host.NetworkDefinitions.VMNetwork").TokenizedKey | Should -Be "Host.NetworkDefinitions.{~ANY~}";
			(Validate-ConfigurationEntry -Key "Host.NetworkDefinitions.VMNetwork.PrimaryDns").TokenizedKey | Should -Be "Host.NetworkDefinitions.{~ANY~}.PrimaryDns";
		}
	}
	
	Context "Host Disks" {
		It "Detects Invalid Keys" {
			(Validate-ConfigurationEntry -Key "Host.Disks").IsValid | Should -Be $false;
			(Validate-ConfigurationEntry -Key "Host.VolumeName").IsValid | Should -Be $false;
			
			(Validate-ConfigurationEntry -Key "Host.ExpectedDisks.VolumeName").IsValid | Should -Be $false;
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "Host.ExpectedDisks").IsValid | Should -Be $true;
			
			(Validate-ConfigurationEntry -Key "Host.ExpectedDisks.BackupsDisk").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "Host.ExpectedDisks.BackupsDisk.VolumeLabel").IsValid | Should -Be $true;
		}
		
		It "Extracts Object Names" {
			(Validate-ConfigurationEntry -Key "Host.ExpectedDisks.BackupsDisk").ObjectInstanceName | Should -Be "BackupsDisk";
			(Validate-ConfigurationEntry -Key "Host.ExpectedDisks.BackupsDisk.VolumeLabel").ObjectInstanceName | Should -Be "BackupsDisk";
		}
		
		It "Tokenizes Disk Names" {
			(Validate-ConfigurationEntry -Key "Host.ExpectedDisks.BackupsDisk").TokenizedKey | Should -Be "Host.ExpectedDisks.{~ANY~}";
			(Validate-ConfigurationEntry -Key "Host.ExpectedDisks.BackupsDisk.VolumeLabel").TokenizedKey | Should -Be "Host.ExpectedDisks.{~ANY~}.VolumeLabel";
		}
	}
	
	Context "ExpectedDirectories" {
		It "Detects Invalid Keys" {
			#(Validate-ConfigurationEntry -Key "ExpectedDirectories.DirectoryName").IsValid | Should -Be $false;  -- actually, nope, this one is LEGIT... "DirectoryName" is the SqlServerInstance name... 
			(Validate-ConfigurationEntry -Key "ExpectedDirectories.MSSQLSERVER.DirectoryName").IsValid | Should -Be $false;
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "ExpectedDirectories.MSSQLSERVER").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ExpectedDirectories.MSSQLSERVER.RawDirectories").IsValid | Should -Be $true;
		}
		
		It "Converts Implicit Keys" {
			(Validate-ConfigurationEntry -Key "ExpectedDirectories.RawDirectories").IsValid | Should -Be $true;
			
			(Validate-ConfigurationEntry -Key "ExpectedDirectories.RawDirectories").NormalizedKey | Should -Be "ExpectedDirectories.MSSQLSERVER.RawDirectories";
		}
		
		It "Extracts the SqlInstance Name" {
			(Validate-ConfigurationEntry -Key "ExpectedDirectories.RawDirectories").SqlInstanceName | Should -Be "MSSQLSERVER";
			(Validate-ConfigurationEntry -Key "ExpectedDirectories.X17.RawDirectories").SqlInstanceName | Should -Be "X17";
		}
		
		It "Tokenizes Valid Keys" {
			(Validate-ConfigurationEntry -Key "ExpectedDirectories.RawDirectories").TokenizedKey | Should -Be "ExpectedDirectories.{~SQLINSTANCE~}.RawDirectories";
		}
	}
	
	Context "ExpectedShares" {
		It "Detects Invalid Keys" {
			(Validate-ConfigurationEntry -Key "ExpectedShares.SourceDirectory").IsValid | Should -Be $false;
			(Validate-ConfigurationEntry -Key "ExpectedShares.Sources.TimeoutValue").IsValid | Should -Be $false;
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "ExpectedShares.SqlBackups").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ExpectedShares.SqlBackups.SourceDirectory").IsValid | Should -Be $true;
		}
		
		It "Tokenizes Valid Keys" {
			(Validate-ConfigurationEntry -Key "ExpectedShares.SqlBackups.SourceDirectory").TokenizedKey | Should -Be "ExpectedShares.{~ANY~}.SourceDirectory";
		}
	}
	
	Context "SqlServerInstallation" {
		It "Detects Invalid Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerInstallation.MSSQLSERVER.DirectoryName").IsValid | Should -Be $false;
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerInstallation.MSSQLSERVER").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "SqlServerInstallation.Setup").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "SqlServerInstallation.MSSQLSERVER.ServiceAccounts").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "SqlServerInstallation.X8.SqlServerDefaultDirectories.SqlDataPath").IsValid | Should -Be $true;
		}
		
		It "Converts Implicit Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerInstallation.Setup").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "SqlServerInstallation.Setup").NormalizedKey | Should -Be "SqlServerInstallation.MSSQLSERVER.Setup";
		}
		
		It "Extracts SqlInstance Name" {
			(Validate-ConfigurationEntry -Key "SqlServerInstallation.Setup").SqlInstanceName | Should -Be "MSSQLSERVER";
			(Validate-ConfigurationEntry -Key "SqlServerInstallation.X8.SqlServerDefaultDirectories.SqlDataPath").SqlInstanceName | Should -Be "X8";
		}
		
		It "Tokenizes Valid Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerInstallation.Setup").TokenizedKey | Should -Be "SqlServerInstallation.{~SQLINSTANCE~}.Setup";
			(Validate-ConfigurationEntry -Key "SqlServerInstallation.X8.SqlServerDefaultDirectories.SqlDataPath").TokenizedKey | Should -Be "SqlServerInstallation.{~SQLINSTANCE~}.SqlServerDefaultDirectories.SqlDataPath";
		}
	}
	
	Context "SqlServerConfiguration" {
		It "Detects Invalid Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerConfiguration.MSSQLSERVER.UserRights").IsValid | Should -Be $false;
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerConfiguration.MSSQLSERVER").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "SqlServerConfiguration.DeployContingencySpace").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "SqlServerConfiguration.MSSQLSERVER.DeployContingencySpace").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "SqlServerConfiguration.X8.EnabledUserRights.PerformVolumeMaintenanceTasks").IsValid | Should -Be $true;
		}
		
		It "Converts Implicit Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerConfiguration.TraceFlags").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "SqlServerConfiguration.TraceFlags").NormalizedKey | Should -Be "SqlServerConfiguration.MSSQLSERVER.TraceFlags";
		}
		
		It "Extracts SqlInstance Name" {
			(Validate-ConfigurationEntry -Key "SqlServerConfiguration.GenerateSPN").SqlInstanceName | Should -Be "MSSQLSERVER";
			(Validate-ConfigurationEntry -Key "SqlServerConfiguration.X8.EnabledUserRights.LockPagesInMemory").SqlInstanceName | Should -Be "X8";
		}
		
		It "Tokenizes Valid Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerConfiguration.GenerateSPN").TokenizedKey | Should -Be "SqlServerConfiguration.{~SQLINSTANCE~}.GenerateSPN";
			(Validate-ConfigurationEntry -Key "SqlServerConfiguration.X8.EnabledUserRights.LockPagesInMemory").TokenizedKey | Should -Be "SqlServerConfiguration.{~SQLINSTANCE~}.EnabledUserRights.LockPagesInMemory";
		}
	}
	
	Context "SqlServerPatches" {
		It "Detects Invalid Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerPatches.MSSQLSERVER.SpLevel").IsValid | Should -Be $false;
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerPatches.MSSQLSERVER").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "SqlServerPatches.TargetCU").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "SqlServerPatches.MSSQLSERVER.TargetCU").IsValid | Should -Be $true;
		}
		
		It "Converts Implicit Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerPatches.TargetCU").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "SqlServerPatches.TargetCU").NormalizedKey | Should -Be "SqlServerPatches.MSSQLSERVER.TargetCU";
		}
		
		It "Extracts SqlInstance Name" {
			(Validate-ConfigurationEntry -Key "SqlServerPatches.TargetCU").SqlInstanceName | Should -Be "MSSQLSERVER";
			(Validate-ConfigurationEntry -Key "SqlServerPatches.X8.TargetCU").SqlInstanceName | Should -Be "X8";
		}
		
		It "Tokenizes Valid Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerPatches.TargetSP").TokenizedKey | Should -Be "SqlServerPatches.{~SQLINSTANCE~}.TargetSP";
			(Validate-ConfigurationEntry -Key "SqlServerPatches.X8.TargetCU").TokenizedKey | Should -Be "SqlServerPatches.{~SQLINSTANCE~}.TargetCU";
		}
	}
	
	Context "AdminDb" {
		It "Detects Invalid Keys" {
			(Validate-ConfigurationEntry -Key "AdminDb.MSSQLSERVER.Install").IsValid | Should -Be $false;
			(Validate-ConfigurationEntry -Key "AdminDb.X8.InstanceSettings.CTFP").IsValid | Should -Be $false;
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "AdminDb.MSSQLSERVER").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AdminDb.OverrideSource").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AdminDb.MSSQLSERVER.InstanceSettings").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AdminDb.X8.InstanceSettings.MAXDOP").IsValid | Should -Be $true;
		}
		
		It "Converts Implicit Keys" {
			(Validate-ConfigurationEntry -Key "AdminDb.InstanceSettings").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AdminDb.InstanceSettings").NormalizedKey | Should -Be "AdminDb.MSSQLSERVER.InstanceSettings";
		}
		
		It "Extracts SqlInstance Name" {
			(Validate-ConfigurationEntry -Key "AdminDb.DiskMonitoring").SqlInstanceName | Should -Be "MSSQLSERVER";
			(Validate-ConfigurationEntry -Key "AdminDb.X8.DiskMonitoring.WarnWhenFreeGBsGoBelow").SqlInstanceName | Should -Be "X8";
		}
		
		It "Tokenizes Valid Keys" {
			(Validate-ConfigurationEntry -Key "AdminDb.ConsistencyChecks").TokenizedKey | Should -Be "AdminDb.{~SQLINSTANCE~}.ConsistencyChecks";
			(Validate-ConfigurationEntry -Key "AdminDb.X8.ConsistencyChecks.StartTime").TokenizedKey | Should -Be "AdminDb.{~SQLINSTANCE~}.ConsistencyChecks.StartTime";
		}
	}
	
	Context "DataCollectorSets" {
		It "Detects Invalid Keys" {
			(Validate-ConfigurationEntry -Key "DataCollectorSets.Enabled").IsValid | Should -Be $false;
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "DataCollectorSets.BlockedProcesses").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "DataCollectorSets.Mirroring.EnableStartWithOS").IsValid | Should -Be $true;
		}
		
		It "Tokenizes Valid Keys" {
			(Validate-ConfigurationEntry -Key "DataCollectorSets.BlockedProcesses.DaysWorthOfLogsToKeep").TokenizedKey | Should -Be "DataCollectorSets.{~ANY~}.DaysWorthOfLogsToKeep";
		}
	}
	
	Context "ExtendedEvents" {
		
		It "Detects Invalid Keys" {
			(Validate-ConfigurationEntry -Key "ExtendedEvents.MSSQLSERVER.EnableTelemetry").IsValid | Should -Be $false;
			(Validate-ConfigurationEntry -Key "ExtendedEvents.MSSQLSERVER.StartWithSystem").IsValid | Should -Be $false;
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "ExtendedEvents.MSSQLSERVER").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ExtendedEvents.BlockedProcessThreshold").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ExtendedEvents.MSSQLSERVER.BlockedProcessThreshold").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ExtendedEvents.X8.Sessions").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ExtendedEvents.X8.Sessions.Mirroring").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ExtendedEvents.X8.Sessions.Mirroring.SessionName").IsValid | Should -Be $true;
			
			(Validate-ConfigurationEntry -Key "ExtendedEvents.Sessions.BlockedProcesses.DefinitionFile").IsValid | Should -Be $true;
		}
		
		It "Converts Implicit Keys" {
			(Validate-ConfigurationEntry -Key "ExtendedEvents.DisableTelemetry").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ExtendedEvents.DisableTelemetry").NormalizedKey | Should -Be "ExtendedEvents.MSSQLSERVER.DisableTelemetry";
			
			(Validate-ConfigurationEntry -Key "ExtendedEvents.Sessions.Mirroring.SessionName").IsValid | Should -Be $true;
		}
		
		It "Extracts SqlInstance Name" {
			(Validate-ConfigurationEntry -Key "ExtendedEvents.BlockedProcessThreshold").SqlInstanceName | Should -Be "MSSQLSERVER";
			(Validate-ConfigurationEntry -Key "ExtendedEvents.X8.Sessions.BlockedProcesses.Enabled").SqlInstanceName | Should -Be "X8";
		}
		
		It "Extracts ObjectInstance Name" {
			(Validate-ConfigurationEntry -Key "ExtendedEvents.Sessions.BlockedProcesses").ObjectInstanceName | Should -Be "BlockedProcesses";
			(Validate-ConfigurationEntry -Key "ExtendedEvents.MSSQLSERVER.Sessions.BlockedProcesses").ObjectInstanceName | Should -Be "BlockedProcesses";
			(Validate-ConfigurationEntry -Key "ExtendedEvents.X8.Sessions.BlockedProcesses.Enabled").ObjectInstanceName | Should -Be "BlockedProcesses";
		}
		
		It "Tokenizes Valid Keys" {
			(Validate-ConfigurationEntry -Key "ExtendedEvents.BlockedProcessThreshold").TokenizedKey | Should -Be "ExtendedEvents.{~SQLINSTANCE~}.BlockedProcessThreshold";
			(Validate-ConfigurationEntry -Key "ExtendedEvents.X8.Sessions").TokenizedKey | Should -Be "ExtendedEvents.{~SQLINSTANCE~}.Sessions";
			(Validate-ConfigurationEntry -Key "ExtendedEvents.MSSQLSERVER.Sessions.Mirroring").TokenizedKey | Should -Be "ExtendedEvents.{~SQLINSTANCE~}.Sessions.{~ANY~}";
			(Validate-ConfigurationEntry -Key "ExtendedEvents.MSSQLSERVER.Sessions.Mirroring.XelFilePath").TokenizedKey | Should -Be "ExtendedEvents.{~SQLINSTANCE~}.Sessions.{~ANY~}.XelFilePath";
		}
		
		It "Treats Explicit 'Global' Keys as Valid" {
			(Validate-ConfigurationEntry -Key "ExtendedEvents.X17.DisableTelemetry").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ExtendedEvents.MSSQLSERVER.DisableTelemetry").TokenizedKey | Should -Be "ExtendedEvents.{~SQLINSTANCE~}.DisableTelemetry";
			
			(Validate-ConfigurationEntry -Key "ExtendedEvents.MSSQLSERVER.DisableTelemetry").SqlInstanceKeyType | Should -Be "Explicit";
		}
		
		It "Converts Implicit 'Global' Keys" {
			(Validate-ConfigurationEntry -Key "ExtendedEvents.DisableTelemetry").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ExtendedEvents.DisableTelemetry").NormalizedKey | Should -Be "ExtendedEvents.MSSQLSERVER.DisableTelemetry";
			(Validate-ConfigurationEntry -Key "ExtendedEvents.DisableTelemetry").TokenizedKey | Should -Be "ExtendedEvents.{~SQLINSTANCE~}.DisableTelemetry";
			
			(Validate-ConfigurationEntry -Key "ExtendedEvents.DisableTelemetry").SqlInstanceKeyType | Should -Be "Implicit";
		}
		
		It "Converts Implicit ~ANY~ Keys" {
			(Validate-ConfigurationEntry -Key "ExtendedEvents.Sessions.BlockedProcesses").IsValid | Should -Be $true;
		}
	}
	
	Context "SqlServerManagementStudio" {
		It "Detects Invalid Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerManagementStudio.SourceDirectory").IsValid | Should -Be $false;
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "SqlServerManagementStudio.InstallSsms").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "SqlServerManagementStudio.IncludeAzureStudio").IsValid | Should -Be $true;
		}
	}
	
	Context "ClusterConfiguration" {
		It "Detects Invalid Keys" {
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.MSSQLSERVER.ClusterSize").IsValid | Should -Be $false;
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.MSSQLSERVER").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.Setup").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.MSSQLSERVER.ClusterIPs").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.X8.Witness").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.X8.Witness.AzureCloudWitness").IsValid | Should -Be $true;
			
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.Witness.AzureCloudWitness").IsValid | Should -Be $true;
		}
		
		It "Converts Implicit Keys" {
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.Witness.AzureCloudWitness").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.Witness.AzureCloudWitness").NormalizedKey | Should -Be "ClusterConfiguration.MSSQLSERVER.Witness.AzureCloudWitness";
		}
		
		It "Extracts SqlInstance Name" {
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.ClusterName").SqlInstanceName | Should -Be "MSSQLSERVER";
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.X8.ClusterName").SqlInstanceName | Should -Be "X8";
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.MSSQLSERVER.Witness.FileShareWitness").SqlInstanceName | Should -Be "MSSQLSERVER";
		}
		
		It "Tokenizes Valid Keys" {
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.Witness").TokenizedKey | Should -Be "ClusterConfiguration.{~SQLINSTANCE~}.Witness";
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.X8.EvictionBehavior").TokenizedKey | Should -Be "ClusterConfiguration.{~SQLINSTANCE~}.EvictionBehavior";
			(Validate-ConfigurationEntry -Key "ClusterConfiguration.Witness.Quorum").TokenizedKey | Should -Be "ClusterConfiguration.{~SQLINSTANCE~}.Witness.Quorum";
		}
	}
	
	Context "AvailabilityGroups" {
		It "Detects Invalid Keys" {
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.MSSQLSERVER.PortNumber").IsValid | Should -Be $false;
			
			# NOTE: This one is TRICKY. But it's invalid because 'ExpectedDatabases' is a child-key of an AG NAME. 
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.Groups.ExpectedDatabases").IsValid | Should -Be $false;
			# NOTE: also 'tricky' - ReplicaNodes is a child of an AG NAME and don't expect someone would name their AG 'ReplicaNodes'... too meta.
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.N28.Groups.ReplicaNodes").IsValid | Should -Be $false;
			
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.SQLN28.SynchronizationChecks.AddFailoverProcessing").IsValid | Should -Be $true;
			
			# additional key-tests from re-authoring some of the low-level details ... 
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.MSSQLSERVER.SynchronizationChecks.CheckJobs").IsValid | Should -Be $false; # invalid
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.MSSQLSERVER.Groups.MainAG.Piggies").IsValid | Should -Be $false; #invalid
		}
		
		It "Detects Valid Keys" {
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.MSSQLSERVER").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.SynchronizationChecks").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.MSSQLSERVER.SynchronizationChecks").IsValid | Should -Be $true;
			
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.N28.Groups").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.N28.Groups.MainAg").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.N28.Groups.MainAg.ReplicaNodes").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.N28.Groups.MainAg.Listener").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.N28.Groups.MainAg.Listener.IPs").IsValid | Should -Be $true;
			
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.MSSQLSERVER.MirroringEndpoint.Enabled").IsValid | Should -Be $true;
			
			# additional key-tests from re-authoring some of the low-level details ... 
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.Enabled").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.MSSQLSERVER.MirroringEndpoint").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.MSSQLSERVER.MirroringEndpoint.Enabled").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.MSSQLSERVER.Groups").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.MSSQLSERVER.SynchronizationChecks.SyncCheckJobs").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.MSSQLSERVER.Groups.MainAG").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.MSSQLSERVER.Groups.MainAG.ReplicaNodes").IsValid | Should -Be $true;
		}
		
		It "Converts Implicit Keys" {
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.EvictionBehavior").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.EvictionBehavior").NormalizedKey | Should -Be "AvailabilityGroups.MSSQLSERVER.EvictionBehavior";
			
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.Groups.MainAg.Listener.IPs").IsValid | Should -Be $true;
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.Groups.MainAg.Listener.IPs").NormalizedKey | Should -Be "AvailabilityGroups.MSSQLSERVER.Groups.MainAg.Listener.IPs";
		}
		
		It "Extracts SqlInstance Name" {
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.EvictionBehavior").SqlInstanceName | Should -Be "MSSQLSERVER";
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.Groups.MainAg.Listener.IPs").SqlInstanceName | Should -Be "MSSQLSERVER";
			
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.N18.Groups.MainAg.Listener.IPs").SqlInstanceName | Should -Be "N18";
		}
		
		It "Extracts ObjectInstance Name" {
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.Groups.MainAg.Listener.IPs").ObjectInstanceName | Should -Be "MainAg";
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.N18.Groups.SqlAG.Listener.IPs").ObjectInstanceName | Should -Be "SqlAG";
		}
		
		It "Tokenizes Valid Keys" {
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.Groups.MainAg.Listener.IPs").TokenizedKey | Should -Be "AvailabilityGroups.{~SQLINSTANCE~}.Groups.{~ANY~}.Listener.IPs";
			(Validate-ConfigurationEntry -Key "AvailabilityGroups.N18.Groups.SqlAG.Listener.IPs").TokenizedKey | Should -Be "AvailabilityGroups.{~SQLINSTANCE~}.Groups.{~ANY~}.Listener.IPs";
		}
	}
	
	Context "ResourceGovernor" {
		# this'll need the same tests as AGs... i.e., invalid keys, valid keys, implicit keys, sql extraction, object extraction, full tokenization.
	}
	
	Context "CustomSqlScripts" {
		# this'll need the same tests as AGs... i.e., invalid keys, valid keys, implicit keys, sql extraction, object extraction, full tokenization.
	}
}