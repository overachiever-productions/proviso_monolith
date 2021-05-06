Set-StrictMode -Version 1.0;

function Deploy-AdminDb {
	param (
		[string]$Source = "https://api.github.com/repos/overachiever-productions/S4/releases/latest"
	);
	
	# default to pulling the file down from online repo - i.e., latest release - UNLESS an explicit file/path has been specified. 
	if (-not [string]::IsNullOrEmpty($Source)) {
		# $AdminDbLatestSqlFilePath must end in a .sql extension - i.e., FILE PATH - not directory to the folder.
		if (-not ($Source -like "*.sql")) {
			throw "-Source must be the path to a valid .sql file (not a directory).";
		}
	}
	else {
		
		$filePath = $PWD;
		
		$release = Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/overachiever-productions/S4/releases/latest";
		$file = ($release.assets | Where-Object {
				$_.name -like "*.sql"
			})[0].browser_download_url;
		
		$outFile = $filePath | Join-Path -ChildPath "admindb_latest.sql";
		
		Invoke-WebRequest -Method GET -Uri $file -OutFile $outFile;
		
		$AdminDbLatestSqlFilePath = $outFile;
	}
	
	# Only installs if NOT already installed:
	Install-SqlServerPowerShellModule;
	
	Invoke-SqlCmd -InputFile $AdminDbLatestSqlFilePath -DisableVariables;
}

#
## $AdminDbLatestSqlFilePath must end in a .sql extension - i.e., FILE PATH - not directory to the folder.
#if (-not ($AdminDbLatestSqlFilePath -like "*.sql")) {
#	throw "-AdminDbLatestSqlFilePath must be the path to a valid .sql file (not a directory).";
#}
#
#if ($CheckOnlineForLatestAdminDbSqlFile) {
#	$filePath = $AdminDbLatestSqlFilePath | Split-Path -Parent;
#	
#	$release = Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/overachiever-productions/S4/releases/latest";
#	$file = ($release.assets | Where-Object {
#			$_.name -like "*.sql"
#		})[0].browser_download_url;
#	
#	$outFile = $filePath | Join-Path -ChildPath "admindb_latest.sql"
#	
#	Invoke-WebRequest -Method GET -Uri $file -OutFile $outFile;
#}