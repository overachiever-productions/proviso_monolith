Set-StrictMode -Version 1.0;

<#

	NOTE: 
		$ConfigFilePath is used to grab a .ini that will be used as a TEMPLATE for installation. 
		Once the file is grabbed, it's turned into a hashtable/PSCumstomObject and then: 
			a. other config values (such as paths and other details from proviso) are INJECTED into said hashtable
            b. a new .ini is generated locally (C:\Scripts\<host-name>_SQL_CONFIG_##.ini)
			c. and the local .ini is used for installation. 

		This allows a documented copy of the .ini to reside on-box 
		NOTE that passwords for services/SA are NOT serialized into the local .ini (they're passed in as command-line switches/params).

	NOTE:
		It WOULD be nicer to use Start-Process instead of Invoke-Command, BUT: too many odd prompts (even if/when -Confirm is set) about " 'are you sure' you want to run xyz from such and such location"... 
		Actually, could just be that I was a moron and set -Confirm:$true ... which is stupid... i.e., -Confirm isn't the 'answer' to a Confirm dialog, it's "do you WANT to throw up the confirm dialog or NOT"

	vNEXT: account for managed service accounts as part of installation.


	NOTE: In my lab I can install SQL SErver with domain users as the Service Accounts - cuz NTLM lets me 'verify' their passwords/etc. 
				In, say, AWS - where ... there might be different PASSWORDs per BOX for each VM and (more importantly) where the password for the DOMAIN ADMIN <> local-Administrator
					SQL SErver throws a nasty "RPC Server Unavailable" when ATTEMPTING to validate installation/setup ... and just terminates with lame errors/messages. 

#>

function Install-SqlServer {
	
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$SQLServerSetupPath,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$ConfigFilePath,
		[Parameter(Mandatory = $true)]
		[hashtable]$SqlDirectories,
		[string]$SaPassword,
		[string[]]$SysAdminAccountMembers,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$SqlServiceAccountName, 
		[string]$SqlServiceAccountPassword = "",
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$AgentServiceAccountName,
		[string]$AgentServiceAccountPassword = "",
		[string]$LicenseKey 
	);
	
	$admins = $SysAdminAccountMembers -join ", ";

	$iniData = Read-SqlIniFile -FilePath $ConfigFilePath;
	
	if (-not([string]::IsNullOrEmpty($LicenseKey))) {
		Add-SqlIniValue -IniData $iniData -Key "PID" -Value $LicenseKey;
	}
	Add-SqlIniValue -IniData $iniData -Key "SQLSVCACCOUNT" -Value $SqlServiceAccountName;
	
	Add-SqlIniValue -IniData $iniData -Key "SQLSYSADMINACCOUNTS" -Value $admins;
	Add-SqlIniValue -IniData $iniData -Key "AGTSVCACCOUNT" -Value $AgentServiceAccountName;
	Add-SqlIniValue -IniData $iniData -Key "INSTALLSQLDATADIR" -Value $SqlDirectories.InstallSqlDataDir;
	Add-SqlIniValue -IniData $iniData -Key "SQLUSERDBDIR" -Value $SqlDirectories.SqlDataPath;
	Add-SqlIniValue -IniData $iniData -Key "SQLUSERDBLOGDIR" -Value $SqlDirectories.SqlLogsPath;
	Add-SqlIniValue -IniData $iniData -Key "SQLBACKUPDIR" -Value $SqlDirectories.SqlBackupsPath;
	Add-SqlIniValue -IniData $iniData -Key "SQLTEMPDBDIR" -Value $SqlDirectories.TempDbPath;
	
	$localIniFilePath = New-LocalSqlIniFilePath;
	Write-SqlIniFile -IniData $iniData -OutputPath $localIniFilePath;
	
	$arguments = @();
	
	$arguments += "/ConfigurationFile='$localIniFilePath' ";
	
	if (-not($SqlServiceAccountName -like "NT SERVICE\*")) {
		$arguments += "/SQLSVCPASSWORD='$SqlServiceAccountPassword' ";
	}
	if (-not($AgentServiceAccountName -like "NT SERVICE\*")) {
		$arguments += "/AGTSVCPASSWORD='$AgentServiceAccountPassword' ";
	}
	
	if (-not([string]::IsNullOrEmpty($SaPassword))) {
		$arguments += "/SAPWD='$SaPassword' ";
		$arguments += "/SECURITYMODE='SQL' ";
	}
	
	$installCommand = "& '$($SQLServerSetupPath)' ";
	foreach ($arg in $arguments) {
		$installCommand += $arg;
	}
	
	Invoke-Expression $installCommand;
}