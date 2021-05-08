Set-StrictMode -Version 3.0;

function Deploy-AdminDb {
	param (
		[string]$Source = "https://api.github.com/repos/overachiever-productions/S4/releases/latest"
	);
	
	$filePath = $PWD;
	
	$release = Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/overachiever-productions/S4/releases/latest";
	$file = ($release.assets | Where-Object {
			$_.name -like "*.sql"
		})[0].browser_download_url;
	
	$outFile = $filePath | Join-Path -ChildPath "admindb_latest.sql";
	
	Invoke-WebRequest -Method GET -Uri $file -OutFile $outFile;
	
	$AdminDbLatestSqlFilePath = $outFile;
	
	# Only installs if NOT already installed:
	Install-SqlServerPowerShellModule;
	
	Invoke-SqlCmd -InputFile $AdminDbLatestSqlFilePath -DisableVariables;
}