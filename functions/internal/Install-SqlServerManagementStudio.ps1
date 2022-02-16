Set-StrictMode -Version 1.0;

filter Install-SqlServerManagementStudio {
	param (
		[string]$Binaries,
		[string]$InstallPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18",
		[switch]$IncludeAzureDataStudio = $false
	);
	
	# NOTE: latest version of SSMS can be DOWNLOADED from: https://aka.ms/ssmsfullsetup
	# Install Docs: https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver15#unattended-install
	
	$arguments = @();
	
	$arguments += "/passive"; # vs quiet... 
	$arguments += "/norestart";
	$arguments += "/install";
	#$arguments += "/log 'C:\Scripts\ssms_'";
	
	if ((-not ([string]::IsNullOrEmpty($InstallPath)) -and ($InstallPath -ne "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18"))) {
		$arguments += "SSMSInstallRoot='$InstallPath'";
	}
	
	if (-not ($IncludeAzureDataStudio)) {
		$arguments += "DoNotInstallAzureDataStudio=1";
	}
	
	$PVContext.WriteLog("Starting (quiet) installation of SSMS.exe.", "Important");
	
	try {
		$PVContext.WriteLog("SSMS Binaries and Arguments: $Binaries $arguments", "Debug");
		
		& "$Binaries" $arguments | Out-Null;
		
		$PVContext.WriteLog("SSMS Installation Complete", "Verbose");
	}
	catch {
		throw "Exception during installation of SSMS: $_ ";
	}
}