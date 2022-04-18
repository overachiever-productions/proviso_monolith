Set-StrictMode -Version 1.0;

<# 

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Assign -ProvisoRoot "\\storage\Lab\proviso\";

	#Write-Host "Count: $($PVCatalog.HostCount())";

	$PVCatalog.GetEnumeratedHosts();

#>

$global:PVCatalog = [Proviso.ProvisoCatalog]::Instance;

[ScriptBlock]$enumerateHosts = {
	param (
		[Parameter(Mandatory)]
		[string]$RootDirectory
		# vNEXT: [string[]]$AllowedExtensions = @("psd1","json","yaml", "etc")
	);
	
	if (-not (Test-Path -Path $RootDirectory -ErrorAction SilentlyContinue)) {
		throw "Invalid Root Directory for Host Enumeration Provided. The path [$RootDirectory] is not valid.";
	}
	
	$this.ResetHostDefnitions();
	
	$files = Get-ChildItem -Path $RootDirectory -Filter "*.psd1" -Recurse;
	foreach ($file in $files) {
		$fileName = $file.BaseName;
		$fullPath = $file.FullName;
		
		try {
			$config = Import-PowerShellDataFile $fullPath;
			
			$configTargetHostName = $config.Host.TargetServer;
			if ($fileName -eq $configTargetHostName) {
				$this.AddHostDefinition($configTargetHostName, $fullPath);
			}
		}
		catch {
			$message = "Error importing Proviso Config File at [$fullPath].`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
			$PVContext.WriteLog($message, "IMPORTANT");
		}
	}
}

[ScriptBlock]$getEnumeratedHostNames = {
	$output = $this.GetDefinedHostNames();
	
	$output;
}

Add-Member -InputObject $PVCatalog -MemberType ScriptMethod -Name EnumerateHosts -Value $enumerateHosts;
Add-Member -InputObject $PVCatalog -MemberType ScriptMethod -Name GetEnumeratedHosts -Value $getEnumeratedHostNames;