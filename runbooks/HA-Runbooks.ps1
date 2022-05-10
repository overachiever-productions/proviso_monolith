Set-StrictMode -Version 1.0;

Runbook Cluster -RequiresDomainCredentials {
	Run-ClusterPrerequisites;
	Run-ClusterConfiguration;
}

#Runbook AvailabilityGroups -RequiresDomainCredentials {
#	
#	Run-EndpointThingies;
#	Run-ExpectedSycnChecks;
#	Run-ExpectedAGs;
#	Run-ExpectedListeners;
#	Run-ExpectedAGDatabases; # for each AG... ensure that each DB is in it... and seed... etc. 
#}