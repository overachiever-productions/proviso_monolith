Set-StrictMode -Version 1.0;

filter Get-ExistingSqlServerInstanceNames {
	
	[string[]]$output = @();
	
	$key = Get-Item 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server' -ErrorAction SilentlyContinue;
	if (($key -eq $null) -or ([string]::IsNullOrEmpty($key.Property))) {
		return $output;
	}
	
	[string[]]$output = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances;
	return $output;
}

# REFACTOR: major screw-up in using these helpers: https://overachieverllc.atlassian.net/browse/PRO-179
filter Get-SqlServerDefaultDirectoryLocation {
	
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$InstanceName,
		[Parameter(Mandatory)]
		[PSCustomObject]$SqlDirectory
	);
	
	# vNEXT can, eventually allow for default directories in the form of "D:\<instanceName>\<directoryName>" and if/when the <instanceName> is MSSQLSERVER... then replace <instanceName> with "" or whatever so that we just get "D:\<directoryName>"
	#  		otherwise, we'd get, say: "D:\X3\SQLData" and so on... 
	
	switch ($SqlDirectory) {
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

# REFACTOR: major screw-up in using these helpers: https://overachieverllc.atlassian.net/browse/PRO-179
filter Get-SqlServerDefaultServiceAccount {
	
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$InstanceName,
		[Parameter(Mandatory)]
		[PSCustomObject]$AccountType
	);
	
	# vNEXT: spin this up to use the defined SVC accounts for named-instances as well... i.e., not hard to do at all... 
	
	#Write-Host "InstanceName: $InstanceName -> account: $AccountType "
	
	switch ($AccountType) {
		"SqlServiceAccountName" {
			return "NT SERVICE\MSSQLSERVER";
		}
		"AgentServiceAccountName" {
			return "NT SERVICE\SQLSERVERAGENT";
		}
		"FullTextServiceAccount" {
			return "NT Service\MSSQLFDLauncher";
		}
		default {
			throw "Default SQL Server Service Accounts for anything other than SQL Server and SQL Server Agent are not, currently, support for anything other than MSSQLSERVER instance.";
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
			
			# CRITICAL: escape ' with '' and escape " with \"  (otherwise complex/high-crypto passwords FAIL and/or crash the installation process):
			$SqlServiceAccountPassword = $ServiceAccounts["SqlServiceAccountPassword"];
			$SqlServiceAccountPassword = $SqlServiceAccountPassword -replace '''', '''''';
			$SqlServiceAccountPassword = $SqlServiceAccountPassword -replace '"', '\"';
			
			$arguments += "/SQLSVCPASSWORD='$SqlServiceAccountPassword' ";
		}
		
		if ($ServiceAccounts["AgentServiceAccountName"] -notlike "NT SERVICE\*") {
			
			# as above, CRITICAL to escape/replace problematic chars:
			$AgentServiceAccountPassword = $ServiceAccounts["AgentServiceAccountPassword"];
			$AgentServiceAccountPassword = $AgentServiceAccountPassword -replace '''', '''''';
			$AgentServiceAccountPassword = $AgentServiceAccountPassword -replace '"', '\"';
			
			$arguments += "/AGTSVCPASSWORD='$AgentServiceAccountPassword' ";
		}
		
		if ($Features -like '*FullText*') {
			if ($ServiceAccounts["FullTextServiceAccount"] -notlike "NT SERVICE\*") {
				
				# as above, CRITICAL to escape/replace problematic chars:
				$FullTextServiceAccountPassword = $ServiceAccounts["FullTextServicePassword"];
				$FullTextServiceAccountPassword = $AgentServiceAccountPassword -replace '''', '''''';
				$FullTextServiceAccountPassword = $AgentServiceAccountPassword -replace '"', '\"';
				
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
		switch ($Version) {
			"2019" {
				$2019 = "SQL Server 2019 transmits information about your installation experience, as well as other usage and performance data, to Microsoft to help improve the product. To learn more about SQL Server 2019 data processing and privacy controls, please see the Privacy Statement."
				$outcome = $outcome -replace $2019, ""
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