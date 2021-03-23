Set-StrictMode -Version 1.0;

# current implementation-ish of this is here: D:\Dropbox\Repositories\S4\S4 Tools\workflows\Build-Server.ps1


# yeah, sadly, workflows won't cut it - they're too small a subset of PowerShell... (or, maybe they'd work, but I'm probably not ready to set them up yet.)
#workflow Build-Server {
#	param (
#		[Parameter(Mandatory = $true)]
#		[string]$TargetServerName,
#		
#	);
#	
#	
#}

# Instead, I'm going to need to look at creating a multi-part function - i.e., something that can figure where it is in terms of overall state
# 		by either dropping files on to the disk somewhere (for state preservation), or the registry or whatever. 

# Here's some fodder: 
#		- https://stackoverflow.com/questions/15166839/powershell-reboot-and-continue-script
#		- https://docs.microsoft.com/en-us/troubleshoot/windows-server/user-profiles-and-logon/turn-on-automatic-logon
#		- https://www.reddit.com/r/PowerShell/comments/83w2bm/install_script_resume_after_restart/
#		- https://cmatskas.com/configure-a-runonce-task-on-windows/


# BUT, the point is that I'd like this ENTIRE, single, function (Build-Server) to seamlessly wrap those capabilities. 
# 		with the idea that the 'workflow' for execution will look something like: 
# 			- log into the new VM (initially, remoting will be the approach for vNext/etc.)
#			- fire off a call to Build-Server with parameters like: 
# 					> Name of the .psd1 file to load (i.e., which target definition to use)
#                   > Creds for any domain join/server-rename/etc. 
#  					> path to resources - like admindb, data collectors, etc. 
#                   > optional info on who to email if there are problems/etc. and so on... 


function Mount-Directory {
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$TargetServerName,	 # new name i.e., can/will be the name of the server in the .psd1 file IF machine is currently something like WIN-ew598u430958
		[Parameter(Mandatory = $true)]
		[string]$ConfigFilePath
		# $OptionalStateFilePath - e.g., C:\temp\proviso\build_state.json or whatever... 
		# $OptionalStepId - 1, 2, 3, 4... whatever
	);
	
	# basic worflow will be: 
	#   create define a 'build_state.json' file somewhere - if there isn't already one
	# 			this file will have basic info on different steps + meta-data about start time and so on... 
	#  		if file doesn't exist, create it and go on to phase1: 
	
	
	# phase 1 (high-level) steps/operations
	#    1. check for and build (if not present) build_state.json (or whatever).
	#    2. read in definitions file + evaluate/etc. 
	#    3. NICs + verify paths and anything else... 
	#    4. rename server. drop info into build_json file - i.e., about server rename. 
	#    4.b. create a job to start when the server restarts. 
	#    5. reboot. (or, if the machine name is already correctly set - mark that as checked/done, and move on to phase 2)
	
	# phase 2 
	#    1. job from above (4.b) should try to direct us into phase2 as the start - just need to make sure there's logic in 
	# 		the overall script to make sure that this happens regardless - i.e., if the file exists and we somehow got started on this function AGAIN
	#       then we need our state/place held and restarted. 
	
	#    2. now that the machine name matches our .psd1 file, DISKs. 
	#    3. SQL Server pre-install and such. 
	#    4. Install SQL Server 
	#    5. admindb 
	#    6. etc. 
	#    7. Clustering? 
	
	#    N. cleanup/remove the build_state.json file and any jobs to tackle during server reboot/startup and so ond.
}