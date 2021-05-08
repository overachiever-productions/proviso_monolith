Set-StrictMode -Version 1.0;

function Expand-ContingencySpace {
	
	param (
		[Parameter(Mandatory = $true)]
		[string[]]$TargetVolumes,
		[Parameter(Mandatory = $true)]
		[string]$ZipSource = "\\storage\Lab\resources\ContingencySpace.zip"
	);
	
	foreach ($volume in $TargetVolumes) {
		$targetPath = "$($volume):\";
		
		Expand-Archive -Path $ZipSource -DestinationPath $targetPath -Force;
		Copy-Item -Path $ZipSource -Destination "$($targetPath)ContingencySpace\" -Force;
	}
}
