Set-StrictMode -Version 1.0;

<# 
	
	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Map -ProvisoRoot "\\storage\Lab\proviso\";
	
	Assign -PasswordForReboot;

	$PVDomainCreds.RebootCredentials

#>


# TODO: maybe look at creating multiple config-secrets or -ConfigSecret_S_ as a param?
function Assign {
	# Possible Alias for Assign: Specify
	param (
		[System.Object]$SecurityProvider = $null,
		[PSCustomObject]$Secret = $null, 						# e.g., "SqlServerInstallation.SecuritySetup.SaPassword", "Pass@word1"
		[switch]$PasswordForReboot = $false, 			# if true, will request password and store as creds object - for use in reboots/etc.
		[PSCredential]$RebootCredential = $null, 				# full-blown credentails object for setting up reboot operations.
		[PSCredential]$DomainCredential = $null,
		[string]$DomainCredsFromFile = $null,
		[scriptblock]$DomainCredsLookup = $null
	);
	
	begin {
		Validate-MethodUsage -MethodName "Assign";
		
		# TODO: simplify this logic - i.e., use the approach I'm using in Psi -> Invoke-PsiCommand ... 
		$count = 0;
		foreach ($x in @($SecurityProvider, $Secret, $PasswordForReboot, $RebootCredential, $DomainCredential, $DomainCredsFromFile, $DomainCredsLookup)) {
			if ($x) {
				$count++;
			}
		}
		if ($count -lt 1) {
			throw "Invalid Argument. Assign requires at least ONE parameter to be specified when called.";
		}
		
		[PSCredential]$internalDomainCreds = $null;
		[PSCredential]$internalRebootCreds = $null;
		
		if ($Secret) {
			if ($Secret.Count -ne 1) {
				throw "Invalid Argument. A -ConfigSecret can only represent a single key/value combination.";
			}
			
			# verify that the KEY is legit/valid:
			$key = $Secret.Key;
			
			if ($null -eq (Get-ProvisoConfigDefault -Key $key -ValidateOnly)) {
				throw "Invalid ConfigSecret.Key: ([$($key)] specified in Assign for parameter [-ConfigSecret].)";
			}
		}
		
		# verify that -SecurityProvider adheres to expected 'interface':
		if ($SecurityProvider) {
			if (-not ($SecurityProvider.PSObject.Methods.Name -eq "GetValues")) {
				throw "Invalid SecurityProvider defined for -SecurityProvider argument against [Assign]. Does not implement ScriptFunction [GetValues()].";
			}
		}
		
		# verify that -DomainCredential works:
		if ($DomainCredential) {
			
			# see PRO-308: https://overachieverllc.atlassian.net/browse/PRO-308
			# TODO: re-evaluate this ... as in... I THINK that validating these makes a LOT of sense. 
			# ONLY... if i'm on a brand new box, that is NOT domain joined and/or where the NICS haven't even been configured to POINT to the domain
			# 		and I run "Assign -domaincreds xx "... I get a big, fat, lame error... 
#			if (-not (Test-DomainCredentials -DomainCreds $DomainCredential)) {
#				throw "Invalid Domain Credentials - failed to authenticate. ";
#			}
			
			$internalDomainCreds = $DomainCredential;
		}
		
		if ($PasswordForReboot -and $RebootCredential) {
			throw "Invalid Operation. Specify EITHER -RebootCredentials or the -[Get]PasswordForReboot switch - not both.";
		}
		
		if ($RebootCredential) {
			if (-not (Validate-WindowsCredentials -Credentials $RebootCredential)) {
				throw "Invalid Credentials. Supplied -RebootCredentials FAILED to pass validation test.";
			}
			
			$internalRebootCreds = $RebootCredential;
		}
		
		if ($PasswordForReboot) {
			$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
			$internalRebootCreds = (Get-Credential $currentUser);
	
			if (-not (Validate-WindowsCredentials -Credentials $internalRebootCreds)) {
				throw "Invalid Credentials. Supplied -PasswordForReboot (for current user) FAILED to pass validation test.";
			}
		}
		
		# Load domainCreds from file and assign as creds: 
		if ($DomainCredsFromFile) {
			throw "Not yet Implemented.";
			
			#$internalDomainCreds = "loaded from file... ";
		}
	};
	
	process {
		
		if ($SecurityProvider) {
			if ($SecurityProvider.PSObject.Methods.Name -eq "LoadValues") {
				try {
					# TODO: ... in theory... this does whatever is needed to go load/set/define everything necessary within the HashTable for .GetValues()
					$SecurityProvider.LoadValues();
				}
				catch {
					throw "EXCEPTION Executing .LoadValues against SecretProvider within [Assign]: $_ `r$($_.ScriptStackTrace) ";
				}
			}
			
			$secrets = $null;
			try {
				[System.Collections.Hashtable]$secrets = $SecurityProvider.GetValues();
			}
			catch {
				throw "SecretProvider's [GetValues()] ScriptFunction does not return a [HashTable].";
			}
			
			try {
				foreach ($key in $secrets.Keys) {
					$value = $secrets[$key];
					
					$PVConfig.SetValue($key, $value);
				}
			}
			catch {
				throw "EXCEPTION Setting Secured Config Value(s) for SecurityProvider within [Assign]: $_  `r$($_.ScriptStackTrace) ";
			}
		}
		
		if ($Secret) {
			try {
				$PVConfig.SetValue($Secret.Key, $Secret.Value);
			}
			catch {
				throw "EXCEPTION while setting -ConfigSecret within [Assign]: $_  `r$($_.ScriptStackTrace) ";
			}
		}
		
		if ($internalRebootCreds) {
			# TODO: Look at shoving this somewhere else - as in, maybe keep 2x 'Credentials'-type objects or something (one for reboot, one for domain join?)
			$PVDomainCreds.RebootCredentials = $internalRebootCreds;
		}
		
		if ($internalDomainCreds) {
			$PVDomainCreds.SetCredential($internalDomainCreds);
		}
		
		if ($DomainCredsLookup) {
			throw "Not yet implemented... ";
		}
	};
	
	end {
		
	};
}

