Set-StrictMode -Version 1.0;

Runbook "Configure-AdminDb" {
	
	# foreach instance... 
	# if AdminDb is enabled (or set to be enabled/deployed in the config... ) then: 
	
	With "xyz as config" | Secured-By $secureThingy | Invoke {
		<VerbName>-AdminDb;
		<VerbName>-AdminDbInstanceSettings;
		<VerbName>-AdminDbDatabaseMail;
		<VerbName>-AdminDbHistory;
		<VerbName>-AdminDbDiskMoinitoring;
		<VerbName>-AdminDbAlerts;
		<VerbName>-AdminDbIndexMaintenance;
		<VerbName>-AdminDbBackupJobs;
		
		# usually we'll do one of the other..... but no reason both facet 'processors' can't be executed.
		<VerbName>-AdminDbRestoreTestJobs;
		<VerbName>-AdminDbConsistencyChecks;
	};
	
	Summarize -LatestRunbook "Configure-AdminDb"; 
}