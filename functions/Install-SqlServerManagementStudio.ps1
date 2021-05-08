Set-StrictMode -Version 1.0;

function Install-SqlServerManagementStudio {
	param (
		[PSCustomObject]$BinaryPath = "\\storage\Lab\resources\binaries\SqlServer\SSMS-Setup-ENU_18.9.1.exe",
		[switch]$IncludeAzureDataStudio = $false
	);
	
	# right now... the path to the binary is hacked... hard-coded as an MVP implementation... 
	# in the future... that path will be part of the convention surrounding the info in PRO-40: https://overachieverllc.atlassian.net/browse/PRO-40
	
	# BUT... there MAY end up being multiple versions at said path/location... 
	# so I'll need to look into ways to find the latest... 
	
	# NOTE: latest version of SSMS can be DOWNLOADED from: https://aka.ms/ssmsfullsetup
	
	
	$installCommand = "& '$($BinaryPath)' ";
	#$installCommand = "& start `"`" /w  '$($BinaryPath)' ";
	
	$arguments = @();
	
	# seriously: WTF? can't get this crap to work... will NOT do a silent install... 
	#  complete bullshit: https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver15#unattended-install
	$arguments += "/quiet";
	$arguments += "/norestart";
	
	# this is the DEFAULT - shouldn't need to be specified:
	#$arguments += "SSMSInstallRoot='C:\Program Files (x86)\Microsoft SQL Server Management Studio 18'";
	
#	if (!$IncludeAzureDataStudio) {
#		$arguments += "DoNotInstallAzureDataStudio=1"
#	}
#	
	foreach ($arg in $arguments) {
		$installCommand += $arg;
	}
	
	Invoke-Expression $installCommand;
}