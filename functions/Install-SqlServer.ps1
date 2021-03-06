Set-StrictMode -Version 1.0;

function Install-SqlServer {
	
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$SQLServerSetupPath = "Z:\setup.exe",
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$ConfigFilePath = "C:\Scripts\definitions\2019_STANDARD_INSTALL.ini",
		[Parameter(Mandatory = $true)]
		[hashtable]$SqlDirectories,
		[string]$SaPassword,
		[string[]]$SysAdminAccountMembers,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$SqlServiceAccountName,
		# TODO: account for managed service accounts as part of installation.

		[string]$SqlServiceAccountPassword = "",
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$AgentServiceAccountName,
		[string]$AgentServiceAccountPassword = "",
		[string]$LicenseKey = "" #TODO: account for LicenseKey - i'm just dumping it in on the first line... 
	);
	
	$admins = $SysAdminAccountMembers -join ", ";
	if ($SqlServiceAccountName -like "NT SERVICE\*") {
		$SqlServiceAccountPassword = $null;
	}
	if ($AgentServiceAccountName -like "NT SERVICE\*") {
		$AgentServiceAccountPassword = $null;
	}
	
	$installCommand = "$SQLServerSetupPath /ConfigurationFile='$ConfigFilePath' /SAPWD='$SaPassword' $LicenseKey ";
	$installCommand = $installCommand + "/SQLSYSADMINACCOUNTS='$admins' ";
	
	$installCommand = $installCommand + "/SQLSVCACCOUNT='$SqlServiceAccountName' "
	if (![string]::IsNullOrEmpty($SqlServiceAccountPassword)) {
		$installCommand = $installCommand + "/SQLSVCPASSWORD='$SqlServiceAccountPassword' "
	}
	
	$installCommand = $installCommand + "/AGTSVCACCOUNT='$AgentServiceAccountName' ";
	if (![string]::IsNullOrEmpty($AgentServiceAccountPassword)) {
		$installCommand = $installCommand + "/AGTSVCPASSWORD='$AgentServiceAccountPassword' "
	}
	
	$installCommand = $installCommand + "/INSTALLSQLDATADIR='$($SqlDirectories.InstallSqlDataDir)' /SQLUSERDBDIR='$($SqlDirectories.SqlDataPath)' "
	$installCommand = $installCommand + "/SQLUSERDBLOGDIR='$($SqlDirectories.SqlLogsPath)' /SQLBACKUPDIR='$($SqlDirectories.SqlBackupsPath)' "
	$installCommand = $installCommand + "/SQLTEMPDBDIR='$($SqlDirectories.TempDbPath)' "
	#$installCommand = $installCommand +
	
	#Write-Host $installCommand;
	Invoke-Expression $installCommand;
}