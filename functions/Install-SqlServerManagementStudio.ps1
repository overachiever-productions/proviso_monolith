Set-StrictMode -Version 1.0;

function Install-SqlServerManagementStudio {
	param (
		[string]$Binaries,
		[string]$InstallPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18",
		[switch]$IncludeAzureDataStudio = $false
	);
	
	# NOTE: latest version of SSMS can be DOWNLOADED from: https://aka.ms/ssmsfullsetup
	# Install Docs: https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver15#unattended-install
	
	$arguments = @();
	
	$arguments += "/passive";  # vs quiet... 
	$arguments += "/norestart";
	$arguments += "/install";
	#$arguments += "/log 'C:\Scripts\ssms_'";
	
	if ((-not ([string]::IsNullOrEmpty($InstallPath)) -and ($InstallPath -ne "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18"))) {
		$arguments += "SSMSInstallRoot='$InstallPath'";
	}
	
	if (-not ($IncludeAzureDataStudio)) {
		$arguments += "DoNotInstallAzureDataStudio=1";
	}
	
	Write-Host "Starting (quiet) installation of SSMS.exe with the following args: $arguments ";
	
	try {
		
		& "$Binaries" $arguments | Out-Null;
	}
	catch {
		throw "Exception during installation of SSMS: $_ ";
	}
}