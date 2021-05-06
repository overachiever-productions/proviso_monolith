Set-StrictMode -Version 1.0;

function New-WsfcCluster {
	
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$ClusterName,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$PrimaryNode,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$SecondaryNode,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({
				$_ -match [IPAddress]$_
			})]
		[string]$ClusterIP1,
		[ValidateScript({
				$_ -match [IPAddress]$_
			})]
		[string]$ClusterIP2,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$WitnessPath
	)
	
	$clusterIPs = @($ClusterIP1);
	if (![string]::IsNullOrWhiteSpace($ClusterIP2)) {
		$clusterIPs[1] = $ClusterIP2;
	}
	
	New-Cluster -Name $ClusterName -Node $PrimaryNode, $SecondaryNode -StaticAddress $clusterIPs -NoStorage;
	
	Set-ClusterQuorum -FileShareWitness $WitnessPath;
	
	Get-Cluster;
}