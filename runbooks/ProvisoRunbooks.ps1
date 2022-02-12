Set-StrictMode -Version 1.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;

	Assign -ProvisoRoot "\\storage\Lab\proviso";
	Target -HostDefinition "PRO-198"; 
	#Add -SecurityProvider $mythingy;
	#Add -DomainCredsFromFile "some file";

	Validate-ServerInitialization -AllowReboot -NextRunBook "ServerConfiguration";

#>

# NEXT: 
#  	move Summarize -CurrentRunbook into Execute-Runbook;
# 		and give it some switches like: -SummarizeProblemsOnly and -SkipSummarize. 
#   try and move the if($PVContext.RebootRequiredANDAllowed) logic into either Execute-Runbook or Process-Surface... 
#  		as in, there should be some way, in the 'top' of each Surface, to determine if:
# 			a. a reboot is required. And, 
# 			b. if there's RUNBOOK in play
# 			c. the user/caller allowed Reboot... 
# 			d. how long to wait before executing a reboot - i.e., -WaitBeforeRebootFor 5|10|30|60|90Seconds as a simple 'switch/argument' (with validated inputs/options.)
# 		and, then, this is defined as PART of the runbook itself.


#---------------------------------------------------------------------------------------------------------------
# Test Runbook
#---------------------------------------------------------------------------------------------------------------
Runbook Tests -DeferRebootUntilRunbookEnd -WaitBeforeRebootFor 5Seconds {
	Run-TestingSurface;
	Run-TestingSurface;
}


#---------------------------------------------------------------------------------------------------------------
# GreenField Runbooks
#---------------------------------------------------------------------------------------------------------------

runbook ServerInitialization -RequiresDomainCredentials -SummarizeProblemsOnly -DeferRebootUntilRunbookEnd -WaitBeforeRebootFor 60Seconds {
	
	Run-NetworkAdapters;
	Run-ServerName;

}

runbook ServerConfiguration -SummarizeProblemsOnly -WaitBeforeRebootFor 5Seconds {
	
	Run-LocalAdministrators;
	Run-WindowsPreferences;
	Run-RequiredPackages;
	
#	if ($PVContext.RebootRequiredAndAllowed) {
#		Execute-Reboot -After 5Seconds -ResumeCurrentRunbook;
#	}
	
	Run-HostTls;
	Run-FirewallRules;
	
	Run-ExpectedDisks;
	
	Run-SqlInstallation;
	Run-SqlConfiguration;
	
	#Run-SqlSPsAndCus;
	#if ($PVContext.RebootRequiredAndAllowed) {
	#	Execute-Reboot -After 10Seconds -ResumeCurrentRunbook;
	#}
		
	Run-ExpectedDirectories;
	Run-ExpectedShares;
	
 	Run-SsmsInstallation;
}

#runbook AdminDb {
#	Run-AdminDb;
#	Run-AdminDbInstanceSettings;
#	Run-AdminDbDatabaseMail;
#	Run-AdminDbHistory;
#	Run-AdminDbDiskMoinitoring;
#	Run-AdminDbAlerts;
#	Run-AdminDbIndexMaintenance;
#	Run-AdminDbBackupJobs;
#	
#	Run-AdminDbRestoreTestJobs;
#	Run-AdminDbConsistencyChecks;
#}
#
#runbook ServerMonitoring {
#	Run-DataCollectorSets;
#	Run-ExtendedEvents;
#}
#
#
##---------------------------------------------------------------------------------------------------------------
## Standalone/Existing Runbooks
##---------------------------------------------------------------------------------------------------------------
#runbook EphmeralDisks {
#	
#	Run-ExpectedDisks;
#	
#	Run-ExpectedDirectories;
#	Run-ExpectedShares;
#	
#	# TODO: make sure that SQL Server is running. And, if it's not... then start it AND 100% ensure reboot/bounce/restart of SQL Server Agent.
#	
#}
#
#runbook ExistingServerOptimization {
#	# hmm... this might just be something like: 
#	Run-SqlConfiguration;
#	
#	# then.. do AdminDb. 
#	# then... do SomethingOther (i.e., data collectors, extended events, etc.. )
#	#    only, skip SSMS?
#}
#
#
##---------------------------------------------------------------------------------------------------------------
## HA Runbooks
##---------------------------------------------------------------------------------------------------------------
#Runbook ClusterConfiguration -RequiresDomainCredentials {
#	
#	Run-ClusterSomething;
#	Run-WitnessWhatever;
#}
#
#Runbook AvailabilityGroups -RequiresDomainCredentials {
#	
#	Run-EndpointThingies;
#	Run-ExpectedSycnChecks;
#	Run-ExpectedAGs;
#	Run-ExpectedListeners;
#	Run-ExpectedAGDatabases; # for each AG... ensure that each DB is in it... and seed... etc. 
#}
#
##---------------------------------------------------------------------------------------------------------------
## Advanced Runbooks
##---------------------------------------------------------------------------------------------------------------
#Runbook ResourceGovernor {
#	# etc. 
#}
#
#Runbook CustomScripts {
#	# not quite sure how to do this one... but this'd be where to do it... 
#}
#