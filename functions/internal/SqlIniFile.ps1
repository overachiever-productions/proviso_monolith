Set-StrictMode -Version 1.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;

	$iniData = New-IniFile;

	$featuresRaw = $iniData.GetValue("FEATURES");
	Write-Host "Features: $featuresRaw ";
	
	$iniData.SetValue("FEATURES", "SQLENGINE, CONN");

$features = $iniData.GetValue("FEATURES");
Write-Host "Features2: $features ..."

#>

$global:currentProvisoIniData65e8dc56 = $null;
function New-IniFile {
	
	$filePath = Join-Path $ProvisoScriptRoot -ChildPath "\functions\internal\Template.ini";
	
	$data = @{};
	$data["_ORDINALS"] = @{};
	$data["_GROUPS"] = @{};
	
	[int]$ordinal = 0;
	
	switch -regex -file $FilePath {
		"^\[(.+)\]" # Group
		{
			$ordinal++;
			$group = $matches[1];
			$data[$group] = @{
			};
			$data["_GROUPS"][$ordinal] = $group;
		}
		"^(?!;)(.+)\s*=\s*(.*)" # Entry
		{
			$ordinal++;
			$name = $matches[1];
			$value = $matches[2].Trim();
			$data[$group][$name] = $value;
			$data["_ORDINALS"][$ordinal] = "$($group).$($name)";
		}
	}
	
	$output = [PSCustomObject]$data;
	
	[scriptblock]$getValue = {
		param (
			[string]$Key,
			[Parameter(Mandatory)]
			[string]$Group = "OPTIONS"
		);
		
		# TODO: there's got to be a way to use 'this' or something similar... 
		[PSCustomObject]$IniData = $global:currentProvisoIniData65e8dc56;
		
		$output = $IniData.$Group[$Key];
		return $output;
	}
	
	[scriptblock]$addValue = {
		param (
			[string]$Key,
			[Parameter(Mandatory)]
			[string]$Value,
			[string]$Group = "OPTIONS"
		);
		
		# TODO: there's got to be a way to use 'this' or something similar... 
		[PSCustomObject]$IniData = $global:currentProvisoIniData65e8dc56;
		
		$currentOrdinal = $IniData._Ordinals.Keys | Sort-Object -Descending {
			$_
		} | Select-Object -First 1;
		$ordinal = $currentOrdinal + 1;
		
		$IniData.$Group[$Key] = $Value;
		$IniData._ORDINALS[$ordinal] = "$($Group).$($Key)";
	}
	
	[scriptblock]$setValue = {
		param (
			[Parameter(Mandatory)]
			[string]$Key,
			[Parameter(Mandatory)]
			[string]$Value,
			[string]$Group = "OPTIONS"
		);
		
		# TODO: there's got to be a way to use 'this' or something similar... 
		[PSCustomObject]$IniData = $global:currentProvisoIniData65e8dc56;
		
		$IniData.$Group[$Key] = $Value;
	}
	
	[scriptblock]$writeToIniFile = {
		param (
			[Parameter(Mandatory = $true)]
			[string]$OutputPath
		);
		
		[PSCustomObject]$IniData = $global:currentProvisoIniData65e8dc56
		
		$groups = $IniData._GROUPS;
		$ordinals = $IniData._ORDINALS;
		
		$outputFile = New-Item -ItemType file -Path $OutputPath;
		
		foreach ($group in $groups.Keys | Sort-Object {
				$_
			}) {
			$currentGroupName = $groups[$group];
			Add-Content -Path $outputFile -Value "[$($currentGroupName)]";
			
			foreach ($key in $ordinals.Keys | Where-Object {
					$ordinals[$_] -like "$($currentGroupName)*"
				} | Sort-Object {
					$_
				}) {
				$keyName = $ordinals[$key].Replace("$($currentGroupName).", "");
				$value = $IniData.$currentGroupName[$keyName];
				
				if ($keyName -like "SQLSYSADMINACCOUNTS*") {
					$value = ($value).Trim();
				}
				elseif ($value -notlike "`"*`"") {
					$value = "`"$($value)`"";
				}
				
				Add-Content -Path $outputFile -Value "$($keyName) = $($value)";
			}
		}
	}
	
	$output | Add-Member -MemberType ScriptMethod -Name "GetValue" -Value $getValue -Force;
	$output | Add-Member -MemberType ScriptMethod -Name "AddValue" -Value $addValue -Force;
	$output | Add-Member -MemberType ScriptMethod -Name "SetValue" -Value $setValue -Force;
	$output | Add-Member -MemberType ScriptMethod -Name "WriteToIniFile" -Value $writeToIniFile -Force;
	
	$global:currentProvisoIniData65e8dc56 = $output;
	return $output;
}

function New-LocalSqlIniFilePath {
	$rootPath = "C:\Scripts";
	
	if (!(Test-Path -Path $rootPath)) {
		Mount-Directory -Path $rootPath;
	}
	
	[int]$fileNumber = 0;
	[string]$finalPath = "";
	[string]$hostName = $env:COMPUTERNAME;
	
	while ([string]::IsNullOrEmpty($finalPath)) {
		[string]$marker = "_$($fileNumber)";
		
		if ($marker -eq "_0") {
			$marker = "";
		}
		[string]$newPath = Join-Path -Path $rootPath -ChildPath "$($hostName)_SQL_CONFIG$($marker).ini";
		
		if (!(Test-Path -Path $newPath)) {
			$finalPath = $newPath;
		}
		
		$fileNumber++;
		if ($fileNumber -gt 20) {
			break;
		}
	}
	
	if ($finalPath -eq $null) {
		throw "Too many SQL_CONFIG_##.ini files found in C:\Scripts directory. Can't save .ini settings. Terminating.";
	}
	
	return $finalPath;
}