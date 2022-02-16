Set-StrictMode -Version 1.0;

$global:PVContext = [Proviso.ProcessingContext]::Instance;

Filter Write-ProvisoLog {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]$Message,
		[ValidateSet("Critical", "Exception", "Important", "Verbose", "Debug")]
		# Critical/Exception are the same thing...  and only critical/exception + Important should output to console...
		[Parameter(Mandatory)]
		[string]$Level = "Verbose"
	);
	
	begin {
		if (-not ($provisoLogInitialized)) {
			
			# vNEXT: this can/could be a 'global ($script:)' file-path that can/could be set by default to the path below and ... overridden by personal .config files and such.
			Mount-Directory "C:\Scripts";
			Set-PSFLoggingProvider -Name logfile -Enabled:$true -FilePath "C:\Scripts\proviso_log.csv";
			$provisoLogInitialized = $true;
		}
	};
	
	process {
		if ($Level -eq "Exception") {
			$Level = "Critical"; # Exception is just an 'alias' for Critical i.e., a bit easier to remember/use when working in catch blocks/etc. 
		}
		
		Write-PSFMessage -Message $Message -Level $Level;
	};
}
$script:provisoLogInitialized = $false;

[ScriptBlock]$writeLog = {
	param (
		[Parameter(Mandatory)]
		[string]$Message,
		[Parameter(Mandatory)]
		[ValidateSet("Critical", "Exception", "Important", "Verbose", "Debug")]
		[string]$Level = "Verbose"
	);
	
	if ((Get-InstalledModule -Name PSFramework) -or (Get-Module -Name PSFramework)) {
		Write-ProvisoLog -Message $Message -Level $Level;
	}
	else {
		Write-Host "$($Level.ToUpper()): $Message";
	}
}

[ScriptBlock]$translateRunbookVerbToSurfaceVerb = {
	$runbookVerb = $this.CurrentRunbookVerb;
	
	switch ($runbookVerb) {
		("Evaluate") {
			return "Validate";
		}
		("Provision") {
			return "Configure";
		}
		("Document") {
			return "Describe";
		}
		default {
			throw "Proviso Framework Error. Invalid Runbook Verb Detected: [$runbookVerb].";
		}
	}
}

Add-Member -InputObject $PVContext -MemberType ScriptMethod -Name WriteLog -Value $writeLog;
Add-Member -InputObject $PVContext -MemberType ScriptMethod -Name GetSurfaceOperationFromCurrentRunbook -Value $translateRunbookVerbToSurfaceVerb;