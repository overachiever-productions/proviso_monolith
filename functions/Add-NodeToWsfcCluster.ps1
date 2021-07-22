Set-StrictMode -Version 1.0;

function Add-NodeToWsfcCluster {
	# Hmm... so, what's the proccess here for adding nodes within ADDITIONAL subnets? Or... with IPs in different subnets? 
	# It's obviousyly: Add-ClusterNode - but... that doesn't provide ANY option for IP resources/etc. 
	
	# So, I'm guessing that the process is: 1. Add-ClusterNode, 2. 'Manually' modify cluster resources and ADD the IP of the new/additional member, right? (as part of the collection of cluster IPs... )
	
}