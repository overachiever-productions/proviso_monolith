
# needs a better name but... 
# this'll be how to deploy consolidated + job to start it on server start AND job to do cleanup.

# A make sure correct Perflogs/Admin directories exist. 
#    	and, arguably, look at 'compressing' the logs folder

# B copy the "consolidated.xml" + Remove logs/cleanup files to the root of C:\perflogs 

# C create the trace + start it. 

# D run > Enable-DataCollectorForAutoStart

# E run > New-CollectorSetFileCleanupJob 


# done... 