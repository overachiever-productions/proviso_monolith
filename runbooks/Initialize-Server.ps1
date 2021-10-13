Set-StrictMode -Version 1.0;

# Runbooks convention... they should be Verb-<something> ... so... "Ephemeral-Disks" sucks. It should be "Ensure-EphemeralDisks"
#   well... then again... Runbook -For "(SQLServer-)High-Availability" makes plenty of sense... 

Runbook -Name "Initialize-Server" {
	
	
	With "xyz as config" | Secured-By $secureThingy | Invoke {
		Configure-NetworkAdapters; # foreach [networkAdapter] in Host.NetworkDefinition... make sure we've got what we need.
		Configure-IpAddress; # for each [networkAdapter]... ensure that the IP, subnet, and gateway are set as expected. 
		Confgure-DNS; # foreach [networkAdapter]... ensure that DNS is set for primary/secondary as needed. 
		
		Configure-ServerName -AllowReboot; # - ExecuteRebase -Force;
	}
	
	if ($PVContext.RebootRequired) {
		# figure out if ... there's a next Runbook... and set up a job to run that. 
		# otherwise, assuming we're allowed to reboot... do so (either with or without a 'next job')
		
		# if we're NOT allowed to reboot, throw an error and/or write a critical output.
	}
}


Runbook -For "Prep-Host-For-SQLServer" {
	
	With $configPassedIn -Strict | Secured-By $securedThingyPassedIn | Invoke -AllowReboot -NextRunBook $null {
		Configure-WindowsServerPreferences;
		Configure-RequiredPackages -AllowReboot;
		Configure-FirewallRules; # includes hostTls1dot2 only... 
		
		Configure-ExpectedDisks;
		Configure-SqlDirectories;
		
	}
}

Runbook -For "Ephemeral-Disks"  {
	
	With "C:\Scripts\ephemeral_disks.psd1" -Strict | Configure-EphmeralDisks;
	
	if (-not ($PVContext.LastProcessingResult.Succeded)) {
		Send-AlertEmail -NotUsingSql -Subject "Oh ship! drives down... " -Etc;
	} 
}

Runbook -For "Install-SqlServer" {
	
	With $configPassedIn | Secured-By $dynamicSecurityThingy | Invoke {
		Verify-SqlServerPrerequisites -Fatal; # verify stuff like... passwords available (in config/secured-by), and that anything/everything else needed prior to installation (except .binaries) has been configured as expected. machine-name, network, required packages, etc.
		Verify-SqlBinaryResources -Fatal; # using the config... make sure that SqlSetup.exe, SqlIniFile, Sqlpatches, and SSMS, etc. are all accessible... 
		# arguably, the above could also be Configure-SqlBinaryResources - i.e., and contain "Config" blocks that copy/move stuff around as needed (or try to). 
		
		Configure-SqlServerInstallation; # core installation stuff.... 
		Configure-ExpectedSqlDirectoriesAndPermissions; # post install tweak/check for folders + perms and shares + perms. 
		Configure-SqlServerPowerShellModule; # make sure it's installed... and up to date... 
		
		Configure-SqlServerInstance; # disable-sa, set SPN, limit TLS only, UserRightsAssignments, and TraceFlags (this puppy is busy... )
		Configure-ContingencySpace;
		
		Configure-AdminDb; # install, enable-advanced, setup email, and ... run dbo.configure_instance. 
		Configure-AdminDbAlerts; # IO/corruption, severity, disk-space alerts. 
		Configure-AdminDbJobs; # create all of the various jobs and such. (history cleanup, ix maint, stats defrag, consistency checks, backups, restore-tests)
		
		Configure-ExtendedEventsSessions; # disable sqltelemetry/etc. 
		
		Configure-DataCollectorSets;
		
		Configure-SSMS;
	}
}

Runbook -For "High-Availability" {
	
}

Runbook -For "Optimizing-Existing-SqlServer" {
	
	# verify a bunch of stuff. 
	# then... Configure-SqlServerInstallation, Configure-ExpectedDirectoriesAndPerms, Configure-SqlServerPowerShellModule, Configure-SqlServerInstance, contingency-space, etc. 
}