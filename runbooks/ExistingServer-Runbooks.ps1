Set-StrictMode -Version 1.0;

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
#runbook ExistingServerBestPractices {
#	# hmm... this might just be something like: 
#	Run-SqlConfiguration;
#	

#   # add/address monitoring? 
#  	# etc... 
#	# then.. do AdminDb. 
#	# then... do SomethingOther (i.e., data collectors, extended events, etc.. )
#	#    only, skip SSMS?
#}

# runbook AWSKitchenSinkRevamp {
# 		# basically... a set of steps to run to take an AWS 'sql base image' (i.e., kitchen sink install)
# 		# 	and roll it back to something with a minimal footprint. 
#		
# 		#e.g.
# 		Validate-Compute (not Run-Compute... but just validate)
# 		Run-Network
# 		Run-Servername i.e., this kind of stuff. 
# 	
# 		Run-RequiredPackages
# 		etc. 
# 	
# 		Run-SqlInstall -Force:$true  # i.e., some way to REMOVE features. 
# 		other config/needs
# 		and so on... 
#}