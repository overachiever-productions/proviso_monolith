﻿Set-StrictMode -Version 1.0;

$global:PVDomainCreds = [Proviso.DomainCredential]::Instance;

[ScriptBlock]$LoadCredential = {
	param (
		[Parameter(Mandatory)]
		[string]$FilePath
	);
	
	# do whatever it takes to securely load a cache object from disk or whatever... 
	$savedCreds = "these are rehydrated from disk or whatever";
	
	$PVDomainCreds.AddCredential($savedCreds);
}

$global:PVDomainCreds | Add-Member -MemberType NoteProperty -Name RebootCredentials -Value $null -Force;