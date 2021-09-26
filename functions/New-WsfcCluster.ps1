Set-StrictMode -Version 1.0;

function New-WsfcCluster {
	
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$ClusterName,
		[Parameter(Mandatory = $true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory = $true)]
		[string[]]$ClusterNodes,
		[Parameter(Mandatory = $true)]
		[string[]]$ClusterIPs,
		[string]$WitnessPath
	)
	
	# TODO: this should return a ProvisoClusterCreationOutput 'object'... pass/fail, exception, cluster details, etc. 
	
	[ScriptBlock]$ClusterCreation = {
		param (
			[string]$ClusterName,
			[string[]]$ClusterNodes,
			[string[]]$ClusterIPs,
			[string]$WitnessPath
		);
		
		# TODO: make sure the cluster doesn't already exist... 
		# $clusterExists = Get-Cluster $clusterName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;			
		
		# this command, of course, fails - cuz the new context we're in ... doesn't have Proviso loaded:
		#Write-ProvisoLog -Message "Executing Script as $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -Level Important;
		Write-Host "Executing Script as $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)";
		
		New-Cluster -Name $ClusterName -Node $ClusterNodes -StaticAddress $ClusterIPs -NoStorage;
		
		if (!([string]::IsNullOrEmpty($WitnessPath))) {
			$WitnessPath = $WitnessPath.TrimEnd('\'); # \\aws2-dc\clusters\" does NOT work, but "\\aws2-dc\clusters" does... 
			Set-ClusterQuorum -FileShareWitness $WitnessPath;
		}
		
		Get-Cluster;
	}
	
	try {
		#Invoke-Command -ScriptBlock $ClusterCreation -Credential $Credential -ArgumentList $ClusterName, $ClusterNodes, $ClusterIPs, $WitnessPath;
		
		$parameters = @{
			ComputerName = '.' # HAS to be included IF/WHEN -Credential is supplied AND if/when ARGs are specified: https://stackoverflow.com/a/18145769/11191
			ScriptBlock = $ClusterCreation
			Credential  = $Credential
			ArgumentList = $ClusterName, $ClusterNodes, $ClusterIPs, $WitnessPath;
		}
		
		# sigh: EXCEPTION: Parameter set cannot be resolved using the specified named parameters. One or mo
		
		Invoke-Command @parameters;
		
		
	}
	catch {
		Write-ProvisoLog -Message ("EXCEPTION: $_  `r$($_.ScriptStackTrace) ") -Level Critical;
		throw "Fatal Exception attempting creation of cluster: $_ ";
	}
}