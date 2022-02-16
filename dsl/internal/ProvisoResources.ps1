Set-StrictMode -Version 1.0;

<#

	-- Methods: 
		.RootSet  defaults to false... (though... maybe check and see if C:\Scripts\proviso would work - via SetRoot() functionality?
		.GetRoot() 
			spits out the root path or whatever was set ...  as the root path. 
			on FIRST call... if root hasn't been set, 
				will check to see if C:\Scripts\proviso will work as a root... 

		.GetAsset(asset-name)
		.GetServerDefinition 
		.GetBinary
		.GetSQLSOmething
		.Etc... 

		.SetRoot(string path, [optional]$personalConfig)
				validates the path
				validates that core resources/folders are present. 
				sets .Present = true... 
			
				various PATHS can be overwritten by/via $personalconfig

		.SetPersonalConfig($x)
				overrides to various conventionalized paths. 

#>

[PSCustomObject]$global:PVResources = [PSCustomObject]@{
	RootSet = $false
	ProvisoRoot = $null
};

[ScriptBlock]$SetRoot = {
	param (
		[Parameter(Mandatory)]
		[string]$RootPath
	);
	
	if (-not (Test-Path $RootPath)) {
		throw "Invalid Path defined/assigned to `$PVResources via SetRoot() method.";
	}
	
	# vNEXT: Personal Config settings can/will allow these to be overridden. 
	foreach ($dir in "assets", "binaries", "definitions", "repository") {
		if (-not (Test-Path -Path (Join-Path -Path $RootPath -ChildPath $dir))) {
			$PVContext.WriteLog("Proviso Directory [$dir] not found in [$RootPath].", "Important");
		}
	}
	
	$PVResources.RootSet = $true;
	$PVResources.ProvisoRoot = $RootPath;
}

[ScriptBlock]$ValidateRootSet = {
	if (-not ($PVResources.RootSet)) {
		throw "Configuration Error. Access to Proviso Resources can not be determined before `$PVResources.SetRoot() has been called.";
	}
}

[ScriptBlock]$GetAsset = {
	param (
		[Parameter(Mandatory)]
		[string]$Asset,
		[string[]]$AllowedExtensions,
		[switch]$AllowPartialMatches = $false,
		[switch]$CaseSensitive = $true
	);
	
	$PVResources.ValidateRootSet();
	$provisoRoot = $PVResources.ProvisoRoot;
	$matchedPath = $null;
	
	# Asset may be an absolute path - in which case it's an override - and we're done:
	if (Test-Path -Path $Asset -ErrorAction SilentlyContinue) {
		$matchedPath = $Asset;
	}
	
	if ($null -eq $matchedPath) {
		
		foreach ($ext in $AllowedExtensions) {
			if (-not ($ext.StartsWith("."))) {
				$ext = ".$($ext)";
			}
			
			$testPath = Join-Path -Path $provisoRoot -ChildPath "\assets\$($Asset)$($ext)";
			if (Test-Path -Path $testPath) {
				$matchedPath = $testPath;
				break;
			}
		}
		
		if ($AllowPartialMatches) {
			$testPath = Join-Path -Path $provisoRoot -ChildPath "\assets\";
			$matches = Get-ChildItem -Path $testPath -Filter "*$($Asset)*";
			
			if ($matches.Count -eq 1) {
				$matchedPath = $matches[0].FullName;
			}
			if ($matches.Count -gt 1) {
				throw "Error. Attempt to use -PartialMatches for Asset [$Asset] against assets directory resulted in > 1 potential pattern match. Terminating...";
			}
		}
	}
	
	if ($matchedPath -ne $null) {
		if ($CaseSensitive) {
			$parent = Split-Path -Path $matchedPath;
			$child = Split-Path -Path $matchedPath -Leaf;
			
			$object = Get-ChildItem -Path $parent -Filter $child;
			return $object.FullName;
		}
		else {
			return $Asset;
		}
	}
}

[ScriptBlock]$GetSqlSetupExe = {
	param (
		[Parameter(Mandatory)]
		[string]$SetupKey
	);
	
	$PVResources.ValidateRootSet();
	$provisoRoot = $PVResources.ProvisoRoot;
	
	# Allow for hard-coded paths as the 'key' - i.e., overrides of convention can be specified... (e.g., Z:\setup.exe, etc.)
	if (Test-Path -Path $SetupKey) {
		return $SetupKey;
	}
	
	$SetupKey = Join-Path "binaries\sqlserver" -ChildPath $SetupKey;
	
	# TODO: convert this to use Join-Path from Posh 7 - where there's an -AdditionalChildPath switch... 
	[string]$path = Join-Path -Path $provisoRoot -ChildPath $SetupKey
	$path = Join-Path -Path $path -ChildPath "setup.exe";
	if (Test-Path -Path $path) {
		return $path;
	}
	
	return $null;
}

[ScriptBlock]$GetSqlSetupIso = {
	throw "Not Implemented.";
	# NOT sure if this'll do the work to just FIND the iso, or find it, MOUNT IT, and then return a path to, say, U:\setup.exe or whatever... 
}

[ScriptBlock]$GetSsmsBinaries = {
	param (
		[Parameter(Mandatory)]
		$BinaryKey
	);
	
	$PVResources.ValidateRootSet();
	$provisoRoot = $PVResources.ProvisoRoot;
	
	# Allow for hard-coded paths as the 'key' - i.e., overrides of convention can be specified... (e.g., Z:\setup.exe, etc.)
	if (Test-Path -Path $BinaryKey) {
		return $BinaryKey;
	}
	
	$BinaryKey = Join-Path "binaries\ssms" -ChildPath $BinaryKey;
	
	[string]$path = Join-Path -Path $provisoRoot -ChildPath "$($BinaryKey).exe";
	if (Test-Path -Path $path) {
		return $path;
	}
	
	[string]$path = Join-Path -Path $provisoRoot -ChildPath "$BinaryKey";
	if (Test-Path -Path $path) {
		return $path;
	}
	
	return $null;
}

[ScriptBlock]$GetSQLSpOrCu = {
	$PVResources.ValidateRootSet();
	$provisoRoot = $PVResources.ProvisoRoot;
	
	throw "Not Implemented.";
	# need to figure out what kind of folder structure to use here... i.e., it COULD be any of the following: 
	#  ..\binaries\patches
	#  ..\binaries\patches\cus
	#  ..\binaries\patches\sps
	#  ..\binaries\sqlserver\patches
	#  ..\binaries\sqlserver\cus
	#  ..\binaries\sqlserver\sps
	
	# i.e., i need to figure out the best OPTION(s) from above and then implement as needed. 

}

[ScriptBlock]$GetServerDefinition = {
	param (
		[Parameter(Mandatory)]
		[string]$HostName
	);
	
	# TODO: Implement - but the idea is that ... i can just specify a host name and this'll get an associated config.
}

[ScriptBlock]$GetAdminDbPath = {
	param (
		[Parameter(Mandatory)]
		[string]$InstanceName,
		[string]$OverridePath = $null
	);
	
	$adminDbPath = $null;
	
	if (-not ([string]::IsNullOrEmpty($OverridePath))) {
		if (Test-Path -Path $OverridePath) {
			$adminDbPath = $OverridePath;
		}
		else {
			throw "Invalid Server Configuration. Value [OverrideSource] for AdminDb.$InstanceName is invalid. Leave empty or specify a FULL path to admindb_latest.sql";
		}
	}
	else {
		$filePath = "C:\Scripts";
		Mount-Directory $filePath;
		
		$release = Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/overachiever-productions/S4/releases/latest" -TimeoutSec 12 -ErrorAction SilentlyContinue;
		if ($release) {
			$file = ($release.assets | Where-Object {
					$_.name -like "*.sql"
				})[0].browser_download_url;
			
			$outFile = $filePath | Join-Path -ChildPath "admindb_latest.sql";
			Invoke-WebRequest -Method GET -Uri $file -OutFile $outFile;
			
			$adminDbPath = $outFile;
		}
		# otherwise, assume we don't have network connectivity... 
	}
	
	if ($null -eq $adminDbPath) {
		$adminDbPath = $this.GetAsset("admindb_latest", "sql");
	}
	
	if ($null -eq $adminDbPath) {
		throw "Proviso Framework Error. Unable to locate an override, or default (local) copy of admindb_latest.sql - and could NOT download admindb from github.com.";
	}
	
	return $adminDbPath;
}

$PVResources | Add-Member -MemberType ScriptMethod -Name ValidateRootSet -Value $ValidateRootSet;
$PVResources | Add-Member -MemberType ScriptMethod -Name SetRoot -Value $SetRoot;
$PVResources | Add-Member -MemberType ScriptMethod -Name GetAsset -Value $GetAsset;
$PVResources | Add-Member -MemberType ScriptMethod -Name GetSqlSetupExe -Value $GetSqlSetupExe;
$PVResources | Add-Member -MemberType ScriptMethod -Name GetSqlSetupIso -Value $GetSqlSetupIso;
$PVResources | Add-Member -MemberType ScriptMethod -Name GetSsmsBinaries -Value $GetSsmsBinaries;
$PVResources | Add-Member -MemberType ScriptMethod -Name GetSqlSpOrCu -Value $GetSQLSpOrCu;
$PVResources | Add-Member -MemberType ScriptMethod -Name GetAdminDbPath -Value $GetAdminDbPath;

<#

	# usage examples:

	$PVResources.SetRoot("//storage/lab/proviso");
	$x = $PVResources.GetAsset("Consolidated", "xml");
	$y = $PVResources.GetSqlSetupExe("sqlserver_2012_dev");
	$z = $PVResources.GetSsmsBinaries("SSMS-Setup-ENU_18.9.2");

	Write-Host "Set: $($PVResources.RootSet) ";
	Write-Host "Root: $($PVResources.ProvisoRoot) ";
	Write-Host "Path to Consolidated: $x ";
	Write-Host "Path to Sql 12: $y ";
	Write-Host "SSMS Binareis: $z ";

#>