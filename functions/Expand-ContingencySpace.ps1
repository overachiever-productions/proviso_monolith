Set-StrictMode -Version 1.0;

function Expand-ContingencySpace {
	
	param (
		[Parameter(Mandatory = $true)]
		[string[]]$TargetVolumes,
		[Parameter(Mandatory = $true)]
		[string]$ZipSource
	);
	
	foreach ($volume in $TargetVolumes) {
		$deployed = $false;
		if (Test-Path -Path "$($volume):\ContingencySpace\") {
			$count = 0;
			foreach ($child in (Get-ChildItem -Path "$($volume):\ContingencySpace" -Filter "PlaceHolder*.emptyspace")) {
				if ($child.Length / 1GB -eq 1) {
					$count++;
				}
			}
			
			if ($count -eq 4) {
				$deployed = $true;
			}
		}
		
		if (-not ($deployed)) {
			$targetPath = "$($volume):\";
			Expand-Archive -Path $ZipSource -DestinationPath $targetPath -Force;
			Copy-Item -Path $ZipSource -Destination "$($targetPath)ContingencySpace\" -Force;
		}
	}
}