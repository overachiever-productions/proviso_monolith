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