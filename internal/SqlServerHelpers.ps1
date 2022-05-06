Set-StrictMode -Version 1.0;

<#
	
	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Assign -ProvisoRoot "\\storage\Lab\proviso\";
	Target "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1";

	Get-SqlServerDefaultServiceAccount -InstanceName "X3" -AccountType "SqlServiceAccountName"

#>

filter Get-ExistingSqlServerInstanceNames {
	
	[string[]]$output = @();
	
	$key = Get-Item 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server' -ErrorAction SilentlyContinue;
	if (($key -eq $null) -or ([string]::IsNullOrEmpty($key.Property))) {
		return $output;
	}
	
	[string[]]$output = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances;
	return $output;
}

filter Get-ConnectionInstance {
	param (
		[Parameter(Mandatory)]
		[string]$InstanceName
	);
	if ($InstanceName -ne "MSSQLSERVER") {
		return ".\$InstanceName";
	}
	
	return ".";
}

filter Get-SqlServerDefaultInstallationPath {
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$InstanceName,
		[Parameter(Mandatory)]
		[PSCustomObject]$DirectoryName
	);
	
	if ("MSSQLSERVER" -eq $InstanceName) {
		switch ($DirectoryName) {
			"InstallDirectory" {
				return "C:\Program Files\Microsoft SQL Server";
			}
			"InstallSharedDirectory" {
				return "C:\Program Files\Microsoft SQL Server";
			}
			"InstallSharedWowDirectory" {
				return "C:\Program Files (x86)\Microsoft SQL Server";
			}
			default {
				throw "Proviso Framework Error. Invalid Directory-Type defined for Get-SqlServerDefaultInstancePath.";
			}
		}
	}
	
	# TODO: Implement a set of rules/defaults for this (there's probably an existing convention established and documented online):
	return "{~DEFAULT_PROHIBITED~}"
}

filter Get-SqlServerDefaultDirectoryLocation {
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$InstanceName,
		[Parameter(Mandatory)]
		[PSCustomObject]$SqlDirectory
	);
	
	if ("MSSQLSERVER" -eq $InstanceName) {
		switch ($SqlDirectory)
		{
			"InstallSqlDataDir" {
				return "D:\SQLData";
			}
			"SqlDataPath" {
				return "D:\SQLData";
			}
			"SqlLogsPath" {
				return "D:\SQLData";
			}
			"SqlBackupsPath" {
				return "D:\SQLBackups";
			}
			"TempDbPath" {
				return "D:\SQLData";
			}
			"TempDbLogsPath" {
				return "D:\SQLData";
			}
		}
	}
	
	switch ($SqlDirectory) {
		"InstallSqlDataDir" {
			return "D:\$InstanceName\SQLData";
		}
		"SqlDataPath" {
			return "D:\$InstanceName\SQLData";
		}
		"SqlLogsPath" {
			return "D:\$InstanceName\SQLData";
		}
		"SqlBackupsPath" {
			return "D:\$InstanceName\SQLBackups";
		}
		"TempDbPath" {
			return "D:\$InstanceName\SQLData";
		}
		"TempDbLogsPath" {
			return "D:\$InstanceName\SQLData";
		}
	}
}

filter Get-SqlServerDefaultServiceAccount {
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$InstanceName,
		[Parameter(Mandatory)]
		[PSCustomObject]$AccountType
	);
	
	if ("MSSQLSERVER" -eq "$InstanceName") {
		switch ($AccountType) {
			"SqlServiceAccountName" {
				return "NT SERVICE\MSSQLSERVER";
			}
			"AgentServiceAccountName" {
				return "NT SERVICE\SQLSERVERAGENT";
			}
			"FullTextServiceAccountName" {
				return "NT Service\MSSQLFDLauncher";
			}
			default {
				throw "Default SQL Server Service Accounts for anything other than SQL Server and SQL Server Agent are not, currently, support for anything other than MSSQLSERVER instance.";
			}
		}
	}
	else {
		switch ($AccountType) {
			"SqlServiceAccountName" {
				return "NT SERVICE\MSSQL`$$($InstanceName)";
			}
			"AgentServiceAccountName" {
				return "NT SERVICE\SQLAGENT`$$($InstanceName)";
			}
			"FullTextServiceAccountName" {
				return "NT Service\MSSQLFDLauncher`$$($InstanceName)";
			}
			default {
				throw "Default SQL Server Service Accounts for anything other than SQL Server and SQL Server Agent are not, currently, support for anything other than MSSQLSERVER instance.";
			}
		}
	}
}

filter Get-SqlServerInstanceMajorVersion {
	param (
		[string]$Instance = "MSSQLSERVER"
	);
	
	$instances = Get-ExistingSqlServerInstanceNames;
	if ($instances -notcontains $Instance) {
		throw "Target SQL Server Instance: [$Instance] not found/installed.";
	}
	
	
	$data = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\').$Instance;
	if ($null -eq $data) {
		throw "SQL Server Instance $Instance not found or not installed.";
	}
	
	[string[]]$parts = $data.split('.');
	
	$parts[0].Replace("MSSQL", "");
}

filter Get-SqlServerInstanceCurrentVersion {
	param (
		[string]$InstanceName
	);
	
	$version = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $InstanceName) -Query "SELECT CAST(SERVERPROPERTY('ProductVersion') AS sysname) [version]; ").version;
	
	return $version;
}

function Get-SqlServerInstanceDetailsFromRegistry {
	
	param (
		[Parameter(Mandatory)]
		[string]$InstanceName,
		[Parameter(Mandatory)]
		# todo.. limit to just the values defined below...
		[string]$Detail
	);
	
	begin {
		$instanceKey = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\').$InstanceName;
		if ($null -eq $instanceKey) {
			throw "SQL Server Instance [$InstanceName] not found in registry or not installed.";
		}
	};
	
	process {
		
		switch ($Detail) {
			"Collation" {
				return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\Setup").Collation;
			}
			"DefaultBackups" {
				return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\$InstanceName").BackupDirectory;
			}
			"DefaultData" {
				return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\$InstanceName").DefaultData;
			}
			"DefaultLog" {
				return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\$InstanceName").DefaultLog;
			}
			"Edition" {
				$edition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\Setup").Edition;
				return ($edition -replace " Edition", "");
			}
			"Features" {
				throw "Need to figure out how to parse (`"HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\Setup`").FeatureList"
			}
			"MixedMode" {
				$value = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\$InstanceName").LoginMode;
				if (2 -eq $value) {
					return $true;
				}
				return $false;
			}
			"VersionName" {
				$version = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\Setup").Version;
				[string[]]$parts = $version -split '\.';
				
				switch ($parts[0]) {
					15 {
						return "2019";
					}
					14 {
						return "2017";
					}
					13 {
						return "2016";
					}
					12 {
						return "2014"
					}
					11 {
						return "2012"
					}
					10 {
						if ($parts[1] -eq 0) {
							return "2008";
						}
						
						return "2008 R2";
					}
					9 {
						return "2005";
					}
					8 {
						return "2000";
					}
					7 {
						return "SQL Server 7.0";
					}
				}
			}
			"VersionNumber" {
				return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\Setup").Version;
			}
		}
	};
	
	end {
		
	};
}

filter Escape-PasswordCharactersForCommandLineUsage {
	# Passwords loaded-into/specified by .config (or other means) have already been 'escaped' to make them strings. 
	# 		specifically, they SHOULD be wrapped in 'single ticks' instead of being in "double ticks like most other strings". 
	# 				and, if/when there is a tick in the password itself, it should be double-ticked to escape it - like so 'PasswordwithATick''InIt'.
	# 	BUT, handling password strings within PowerShell via ticks + doubling/escaping ticks inside of the password itself is ONLY part of the equation.
	# 		The OTHER part of the puzzle is that passwords 'written out to DOS' as command-line switches need some additional processing. 
	# 			and this filter/func is what handles that logic. 	
	param (
		[Parameter(Mandatory)]
		[string]$Password
	);
	
	$escaped = $Password -replace '''', '''''';
	$escaped = $escaped -replace '"', '\"';
	
	return $escaped;
}

function Install-SqlServer {
	param (
		[switch]$StrictInstallOnly = $false,
		[Parameter(Mandatory)]
		[string]$Version,
		[Parameter(Mandatory)]
		[string]$InstanceName,
		[Parameter(Mandatory)]
		[string]$MediaLocation,
		[Parameter(Mandatory)]
		[string]$Features,
		[Parameter(Mandatory)]
		[hashtable]$Settings,
		[Parameter(Mandatory)]
		[string[]]$SysAdminMembers,
		[Parameter(Mandatory)]
		[hashtable]$InstallationDirectories,
		[Parameter(Mandatory)]
		[hashtable]$ServiceAccounts,
		[Parameter(Mandatory)]
		[hashtable]$SqlDirectories,
		[Parameter(Mandatory)]
		[hashtable]$SqlTempDbDirectives,
		[string]$LicenseKey
	);
	
	begin {
		if ($MediaLocation.EndsWith(".iso")) {
			throw "Installation vs .iso files is not YET supported by Proviso.";
		}
		
		$setupPath = $PVResources.GetSqlSetupExe($MediaLocation);
		if (-not (Test-Path $setupPath)) {
			throw "Invalid Path Specified for SQL Server Installation Media. The path [$setupPath] does not exist - or access is denied.";
		}
		
		$installedInstances = Get-ExistingSqlServerInstanceNames;
		if ($installedInstances -contains $InstanceName) {
			if ($StrictInstallOnly) {
				throw "SQL Server Instance [$InstanceName] has already been installed, and the [StrictInstallOnly] configuration value is set to `$true. Cannot continue. Terminating.";
			}
			
			$PVContext.WriteLog("SQL Server Instance [$InstanceName] has already been installed and Proviso does not, yet, support modifying EXISTING installations. Skipping SQL Server Installation.", "Critical");
			return;
		}
	};
	
	process {
		
		# Create a .ini file for installation: 
		$iniData = New-IniFile;
		
		# Ensure directories: 
		foreach ($dirKey in $SqlDirectories.Keys) {
			$dir = $SqlDirectories.Item($dirKey);
			
			Mount-Directory $dir;
		}
		
		# Define required attributes:
		$iniData.SetValue("INSTANCENAME", "$InstanceName");
		$iniData.SetValue("FEATURES", "$($Features)");
		
		$iniData.SetValue("INSTANCEDIR", "$($InstallationDirectories["InstallDirectory"])");
		$iniData.SetValue("INSTALLSHAREDDIR", "$($InstallationDirectories["InstallSharedDirectory"])");
		$iniData.SetValue("INSTALLSHAREDWOWDIR", "$($InstallationDirectories["InstallSharedWowDirectory"])");
		
		$iniData.SetValue("SQLCOLLATION", "$($Settings["Collation"])");
		$iniData.SetValue("SQLSVCINSTANTFILEINIT", "$($Settings["InstantFileInit"].ToString().ToUpper())");
		$iniData.SetValue("FILESTREAMLEVEL", "$($Settings["FileStreamLevel"])");
		
		$np = "0";
		$tcp = "0";
		if ($Settings["NamedPipesEnabled"]) {
			$np = "1";
		}
		if ($Settings["TcpEnabled"]) {
			$tcp = "1";
		}
		
		$iniData.SetValue("NPENABLED", "$np");
		$iniData.SetValue("TCPENABLED", "$tcp");
		
		$iniData.SetValue("SQLSVCACCOUNT", "$($ServiceAccounts["SqlServiceAccountName"])");
		$iniData.SetValue("AGTSVCACCOUNT", "$($ServiceAccounts["AgentServiceAccountName"])");
		
		if ($Features -like '*FullText*') {
			$iniData.AddValue("FTSVCACCOUNT", "$($ServiceAccounts["FullTextServiceAccount"])");
		}
		
		$iniData.SetValue("INSTALLSQLDATADIR", "$($SqlDirectories["InstallSqlDataPath"])");
		$iniData.SetValue("SQLUSERDBDIR", "$($SqlDirectories["SqlDataPath"])");
		$iniData.SetValue("SQLUSERDBLOGDIR", "$($SqlDirectories["SqlLogsPath"])");
		$iniData.SetValue("SQLBACKUPDIR", "$($SqlDirectories["SqlBackupsPath"])");
		$iniData.SetValue("SQLTEMPDBDIR", "$($SqlDirectories["TempDbPath"])");
		$iniData.SetValue("SQLTEMPDBLOGDIR", "$($SqlDirectories["TempDbLogsPath"])");
		
		$iniData.SetValue("SQLTEMPDBFILECOUNT", "$($SqlTempDbDirectives["SqlTempDbFileCount"])");
		$iniData.SetValue("SQLTEMPDBFILESIZE", "$($SqlTempDbDirectives["SqlTempDbFileSize"])");
		$iniData.SetValue("SQLTEMPDBFILEGROWTH", "$($SqlTempDbDirectives["SqlTempDbFileGrowth"])");
		$iniData.SetValue("SQLTEMPDBLOGFILESIZE", "$($SqlTempDbDirectives["SqlTempDbLogFileSize"])");
		$iniData.SetValue("SQLTEMPDBLOGFILEGROWTH", "$($SqlTempDbDirectives["SqlTempDbLogFileGrowth"])");
		
		if ($Settings["SQLAuthEnabled"]) {
			$iniData.AddValue("SECURITYMODE", "SQL");
		}
		
		if ($SysAdminMembers.Count -gt 0) {
			$serializedSysAdmins = "";
			foreach ($admin in $SysAdminMembers) {
				$serializedSysAdmins += "`"$admin`" "; # e.g., SQLSYSADMINACCOUNTS="SQL-150-AG01A\Administrator" "OVERACHIEVER\Administrator" 
			}
			# NOTE: this ALSO requires SPECIAL formatting/output during the scriptmethod for .WriteToIniFile()
			$iniData.AddValue("SQLSYSADMINACCOUNTS", $serializedSysAdmins);
		}
		
		# TODO: inline this ... New-LocalSqlIniFilePath ... doesn't REQUIRE _ANY_ input from this code... so, just wrap it up into .WriteToIniFile() transparently ... 
		#  		so that i only have to execute: $iniData.WriteToLocalIniFile(); (done)
		$localIniFilePath = New-LocalSqlIniFilePath;
		$iniData.WriteToIniFile($localIniFilePath);
		
		$arguments = @();
		$arguments += "/ConfigurationFile='$localIniFilePath' ";
		
		if (-not ([string]::IsNullOrEmpty($LicenseKey))) {
			$arguments += "/PID='$LicenseKey' ";
		}
		
		if ($ServiceAccounts["SqlServiceAccountName"] -notlike "NT SERVICE\*") {
			$SqlServiceAccountPassword = Escape-PasswordCharactersForCommandLineUsage -Password ($ServiceAccounts["SqlServiceAccountPassword"]);
			$arguments += "/SQLSVCPASSWORD='$SqlServiceAccountPassword' ";
		}
		
		if ($ServiceAccounts["AgentServiceAccountName"] -notlike "NT SERVICE\*") {
			
			$AgentServiceAccountPassword = Escape-PasswordCharactersForCommandLineUsage -Password ($ServiceAccounts["AgentServiceAccountPassword"]);
			$arguments += "/AGTSVCPASSWORD='$AgentServiceAccountPassword' ";
		}
		
		if ($Features -like '*FullText*') {
			if ($ServiceAccounts["FullTextServiceAccount"] -notlike "NT SERVICE\*") {
				# as above, CRITICAL to escape/replace problematic chars:
				$FullTextServiceAccountPassword = Escape-PasswordCharactersForCommandLineUsage -Password ($ServiceAccounts["FullTextServicePassword"]);
				$arguments += "/FTSVCPASSWORD='$FullTextServiceAccountPassword' ";
			}
		}
		
		if ($Settings["SQLAuthEnabled"]) {
			# as above, CRITICAL to escape/replace problematic chars:
			[string]$SaPassword = $Settings["SaPassword"];
			if (([string]::IsNullOrEmpty($SaPassword)) -or ($SaPassword.Length -lt 9)) {
				throw "Sa Password specified is empty or too short (it NEEDS to be 9 or more chars in length.";
			}
			
			$SaPassword = $SaPassword -replace '''', '''''';
			$SaPassword = $SaPassword -replace '"', '\"';
			
			$arguments += "/SAPWD='$SaPassword' ";
		}
		
		$installCommand = "& '$($MediaLocation)' ";
		foreach ($arg in $arguments) {
			$installCommand += $arg;
		}
		
		$outcome = Invoke-Expression $installCommand;
		
		$PVContext.WriteLog("Raw SQL Installation Outcome: $outcome", "Debug");
		
		switch ($Version) {
			"2019" {
				$2019telemetry = "SQL Server 2019 transmits information about your installation experience, as well as other usage and performance data, to Microsoft to help improve the product. To learn more about SQL Server 2019 data processing and privacy controls, please see the Privacy Statement."
				$2019entKey = "Notice: A paid SQL Server edition product key has been provided for the current action - Enterprise. Please ensure you are entitled to this SQL Server edition with proper licensing in place for the product key (edition) supplied.";
				$2019stdKey = "Notice: A paid SQL Server edition product key has been provided for the current action - Standard. Please ensure you are entitled to this SQL Server edition with proper licensing in place for the product key (edition) supplied.";
				
				$outcome = $outcome -replace $2019telemetry, "";
				$outcome = $outcome -replace $2019entKey, "";
				$outcome = $outcome -replace $2019stdKey, "";
			}
			"2017" {
				
			}
			"2016" {
				
			}
		}
		
		if (($outcome -like "*following error occurred:*") -or ($outcome -like "*Error result:*")) {
			$PVContext.WriteLog("SQL Installation Error: $outcome ", "Critical");
			throw "SQL Server Installation Failed. $outcome ";
		}
		
		$PVContext.WriteLog("SQL Install Outcome: $outcome ", "Debug");
	};
	
	end {
		
	};
}

function Install-SqlServerPatch {
	param (
		[switch]$StrictInstallOnly = $false, # hmm... do I even need this? 
		[string]$InstanceName = "MSSQLSERVER",
		[string]$SpOrCuPath
	);
	
	if (-not (Test-Path -Path $SpOrCuPath -ErrorAction SilentlyContinue)) {
		throw "Invalid SQL Server SP or CU Path Specified: [$SpOrCuPath].";
	}
	
	$arguments = @();
	
	$arguments += "/action=Patch";
	$arguments += "/instancename=$InstanceName";
	$arguments += "/quiet";
	$arguments += "/hideconsole";
	$arguments += "/IAcceptSQLServerLicenseTerms";
	
	$PVContext.WriteLog("Starting (quiet) installation of [$SpOrCuPath].", "Important");
	try {
		$PVContext.WriteLog("SP or CU installation binaries and args: $SpOrCuPath $arguments", "Debug");
		
		& "$SpOrCuPath" $arguments | Out-Null;
		
		$PVContext.WriteLog("SP or CU [$SpOrCuPath] Installed.", "Verbose");
	}
	catch {
		throw "Exception during installation of SP or CU [$SpOrCuPath]: $_ ";
	}
}