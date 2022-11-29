﻿Set-StrictMode -Version 1.0;

# TODO: Hmmm. this won't ALWAYS require domain creds ... (i.e., if I'm spinning up boxes for a workgroup... duh)
# 		so... require only if there's a change... 
runbook ServerInitialization -RequiresDomainCredsConfigureOnly -SummarizeProblemsOnly -DeferRebootUntilRunbookEnd -WaitBeforeRebootFor 20Seconds {
	Run-NetworkAdapters;
	Run-ServerName;
}

runbook ServerConfiguration -SummarizeProblemsOnly -WaitBeforeRebootFor 5Seconds {
	# Validate-Compute  # i.e., this one will never be 'CONFIGURE'... at this stage, but it'll be good to know if/when ... the hardware is NOT what it's expected to be.
	
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