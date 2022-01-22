Set-StrictMode -Version 1.0;

<# 
	Runbooks convention... they should be Verb-<something> ... so... "Ephemeral-Disks" sucks. It should be "Ensure-EphemeralDisks" or "Initialize-EphemeralDisks"
	    well... then again... Runbook -For "(SQLServer-)High-Availability" makes plenty of sense... 
	 
	overall, the syntax below... works - i like it. 
	   but... i THINK I'll probably have to look at ways to pass in a -MachineName as a required element in some of these?
	   		e.g., InitializeServer... probably needs a -MachineName passed in. 
	 				at which point, it'll determine if we're on the Host.TargetDomain or not... 
	  							and, if needed, REQUIRE domainAdminCreds... 


 	In other words, I have to spend a bit more time figuring out what the 'caller' for some of these scripts might look like. Something like, say:

	Assume something like this in either a .ps1 or ... from the command-line: 
	> $SecurityThingy = Secured-By Something;
	> $targetMachine = Func-To-Get-A-Name?
	> Initialize-Server -MachineName $targetMachine -SecuredBy $securityThingy -UseConventionsForPathsAndStuff (or -usePersonalConfig@thislocationOrWhatever). 

	> ... the end. 
	I'd still need to bootstrap Proviso into play before running some of the stuff above... but... I'm going to need to PROVIDE: a) proviso, b) security-thingies, c) a machine-name (in many - but not all cases)


#>

Runbook -Name "Initialize-Server" -RequiresDomainCreds {
	
	With "xyz as config" | Secured-By $secureThingy | Invoke {
		<VerbName>-NetworkAdapters;
		<VerbName>-ServerName;
	}
	
	Summarize -All;
	
	if ($PVContext.RebootRequired) {
		Wait-For 40 -seconds;
		# figure out if ... there's a next Runbook... and set up a job to run that. 
		# otherwise, assuming we're allowed to reboot... do so (either with or without a 'next job')
		
		# if we're NOT allowed to reboot, throw an error and/or write a critical output.
	}
}

Runbook -For "Ephemeral-Disks"  {
	
	With "C:\Scripts\ephemeral_disks.psd1" -Strict | Configure-EphmeralDisks;
	
	if (-not ($PVContext.LastProcessingResult.Succeded)) {
		Send-AlertEmail -NotUsingSql -Subject "Oh snap! drives down... " -Etc;
	}
}

Runbook -For "Prep-Host-For-SQLServer" {
	
	With $configPassedIn -Strict | Secured-By $securedThingyPassedIn | Invoke -AllowReboot -NextRunBook $null {
		<VerbName>-LocalAdministrators;
		<VerbName>-WindowsServerPreferences;
		<VerbName>-RequiredPackages -AllowReboot;
		<VerbName>-HostTls;
		<VerbName>-FirewallRules;
		
		<VerbName>-ExpectedDisks;
	}
}

Runbook -For "Install-SqlServer" -ServerName "SQL-xxx-orWhatever" {
	
	With $configPassedIn | Secured-By $dynamicSecurityThingy | Invoke {
		#Verify-SqlServerPrerequisites -Fatal; # verify stuff like... passwords available (in config/secured-by), and that anything/everything else needed prior to installation (except .binaries) has been configured as expected. machine-name, network, required packages, etc.
		#Verify-SqlBinaryResources -Fatal; # using the config... make sure that SqlSetup.exe, SqlIniFile, Sqlpatches, and SSMS, etc. are all accessible... 
		# arguably, the above could also be Configure-SqlBinaryResources - i.e., and contain "Config" blocks that copy/move stuff around as needed (or try to). 
		Validate-SqlServerBinaryResources -Fatal;
		
		<VerbName>-SqlServerInstallation; # core installation stuff.... 
		<VerbName>-ExpectedSqlDirectoriesAndPermissions; # post install tweak/check for folders + perms and shares + perms. 
		<VerbName>-SqlServerPowerShellModule; # make sure it's installed... and up to date... 
		
		<VerbName>-SqlServerInstance; # disable-sa, set SPN, limit TLS only, UserRightsAssignments, and TraceFlags (this puppy is busy... )
		<VerbName>-ContingencySpace;
		
		<VerbName>-AdminDb; # install, enable-advanced, setup email, and ... run dbo.configure_instance. 
		<VerbName>-AdminDbAlerts; # IO/corruption, severity, disk-space alerts. 
		<VerbName>-AdminDbJobs; # create all of the various jobs and such. (history cleanup, ix maint, stats defrag, consistency checks, backups, restore-tests)
		
		<VerbName>-ExtendedEventsSessions; # disable sqltelemetry/etc. 
		
		<VerbName>-DataCollectorSets;
		
		<VerbName>-SSMS;
	}
}

Runbook -For "High-Availability" -RequiresDomainCreds {
	
}

Runbook -For "Optimizing-Existing-SqlServer" {
	
	# verify a bunch of stuff. 
	# then... Configure-SqlServerInstallation, Configure-ExpectedDirectoriesAndPerms, Configure-SqlServerPowerShellModule, Configure-SqlServerInstance, contingency-space, etc. 
}