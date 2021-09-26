Set-StrictMode -Version 1.0;

function Deploy-AdminDb {
	param (
		[string]$OverrideSource
	);
	
	$adminDbPath = $null;

	if (-not ([string]::IsNullOrEmpty($OverrideSource))) {
		if (Test-Path -Path $OverrideSource) {
			$adminDbPath = $OverrideSource;
		}
		else {
			throw "Invalid OverrideSource specified for AdminDb via configuration file. OverrideSource must be an absolute path, a path into the assets folder, or empty (to download from github).";
		}
	}
	else {
		try {
			$filePath = "C:\Scripts";
			Mount-Directory $filePath;
			
			$release = Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/overachiever-productions/S4/releases/latest" -TimeoutSec 8;
			$file = ($release.assets | Where-Object {
					$_.name -like "*.sql"
				})[0].browser_download_url;
			
			$outFile = $filePath | Join-Path -ChildPath "admindb_latest.sql";
			Invoke-WebRequest -Method GET -Uri $file -OutFile $outFile;
			
			$adminDbPath = $outFile;
		}
		catch {
			throw "Error downloading admindb_latest.sql from github. Ensure internet connection or download admindb_latest.sql to assets/admindb_latest.sql and modify config accordingly.";
		}
	}
	
	Invoke-SqlCmd -InputFile $adminDbPath -DisableVariables;
}