Set-StrictMode -Version 3.0;

function Write-SqlIniFile {
	param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$IniData,
		[Parameter(Mandatory = $true)]
		[string]$OutputPath
	);
	
	$groups = $IniData._GROUPS;
	$ordinals = $IniData._ORDINALS;
	
	$outputFile = New-Item -ItemType file -Path $OutputPath;
	
	foreach ($group in $groups.Keys | Sort-Object { $_ } ){
		$currentGroupName = $groups[$group];
		Add-Content -Path $outputFile -Value "[$($currentGroupName)]";
		
		foreach ($key in $ordinals.Keys | Where-Object { $ordinals[$_] -like "$($currentGroupName)*" }| Sort-Object { $_ }){
			$keyName = $ordinals[$key].Replace("$($currentGroupName).", "");
			$value = $IniData.$currentGroupName[$keyName];
			
			if (!($value -like "`"*`"")){
				$value = "`"$($value)`"";
			}
			
			Add-Content -Path $outputFile -Value "$($keyName) = $($value)";
		}
	}
}