﻿Set-StrictMode -Version 1.0;

function Install-NetFx35ForPre2016Instances {
	
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet("Windows2012R2", "Windows2016", "Windows2019")]
		[string]$WindowsServerVersion,
		[string]$NetFxSxsRootPath = "\\storage\Lab\resources\binaries\net3.5_sxs"
	);
	
	$binariesPath = Join-Path -Path $NetFxSxsRootPath -ChildPath $WindowsServerVersion;
	
	$installed = (Get-WindowsFeature Net-Framework-Core).InstallState;
	if ($installed -ne "Installed") {
		Install-WindowsFeature Net-Framework-Core -source $binariesPath
	}
}