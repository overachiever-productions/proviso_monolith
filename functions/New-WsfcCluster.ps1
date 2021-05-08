Set-StrictMode -Version 3.0;

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
	
	New-Cluster -Name $ClusterName -Node $ClusterNodes -StaticAddress $ClusterIPs -NoStorage;
	
	if (!([string]::IsNullOrEmpty($WitnessPath))) {
		# BUG: trim trailing slashes i.e., "\\aws2-dc\clusters\" does NOT work, but "\\aws2-dc\clusters" does... 
		Set-ClusterQuorum -FileShareWitness $WitnessPath;
	}
	
	Get-Cluster;
}