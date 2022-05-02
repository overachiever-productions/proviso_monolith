Set-StrictMode -Version 1.0;

runbook ServerInitialization -RequiresDomainCredentials -SummarizeProblemsOnly -DeferRebootUntilRunbookEnd -WaitBeforeRebootFor 60Seconds {
	Run-NetworkAdapters;
	Run-ServerName;
}

runbook ServerConfiguration -SummarizeProblemsOnly -WaitBeforeRebootFor 5Seconds {
	Run-LocalAdministrators;
	Run-WindowsPreferences;
	Run-RequiredPackages;
	
	Run-HostTls;
	Run-FirewallRules;
	
	Run-ExpectedDisks;  # MIGHT make sense to move this into ServerInitialization? Except that I commonly need ServerInit in my Lab, but run ServerConfig 'onwards' in client environments... 
	
	Run-SqlInstallation;
	Run-SqlConfiguration;
	
	Run-ExpectedDirectories;
	Run-ExpectedShares;
	
	Run-SqlVersion;
	
	Run-SsmsInstallation;
}

runbook AdminDb {
	Run-AdminDb;
	Run-AdminDbInstanceSettings;
	Run-AdminDbDatabaseMail;
	Run-AdminDbHistory;
	Run-AdminDbDiskMonitoring;
	Run-AdminDbAlerts;
	Run-AdminDbIndexMaintenance;
	Run-AdminDbBackups;
	
	Run-AdminDbRestoreTests;
	Run-AdminDbConsistencyChecks;
}

runbook ServerMonitoring {
	Run-DataCollectorSets;
	Run-ExtendedEvents;
}