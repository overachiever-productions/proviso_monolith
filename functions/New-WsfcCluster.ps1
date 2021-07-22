Set-StrictMode -Version 1.0;


# NOTE: This NEEDs to be run by someone with domain admin creds or with whatever creds are needed to CREATE a cluster AND have 'ownership/admin' perms over the top of each VM/NODE in question... 

function New-WsfcCluster {
	
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$ClusterName,
		[Parameter(Mandatory = $true)]
		[string[]]$ClusterNodes,
		[Parameter(Mandatory = $true)]
		[string[]]$ClusterIPs,
		[string]$WitnessPath
	)
	
	# TODO: make sure the cluster doesn't already exist... 
	
	New-Cluster -Name $ClusterName -Node $ClusterNodes -StaticAddress $ClusterIPs -NoStorage;
	
	if (!([string]::IsNullOrEmpty($WitnessPath))) {
		# BUG: trim trailing slashes i.e., "\\aws2-dc\clusters\" does NOT work, but "\\aws2-dc\clusters" does... 
		Set-ClusterQuorum -FileShareWitness $WitnessPath;
	}
	
	Get-Cluster;
}

# New-Cluster -Name AWS-X -Node "AWS-A.aws.local", "AWS-B.aws.local" -StaticAddress 10.0.30.111, 10.0.31.111 -NoStorage;