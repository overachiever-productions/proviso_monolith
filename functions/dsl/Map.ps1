Set-StrictMode -Version 1.0;

# TODO: maybe look at creating multiple config-secrets or -ConfigSecret_S_ as a param?

function Map {
	[Alias("Add")]
	
	param (
		[System.Object]$SecurityProvider,
		[PSCustomObject]$Secret, 					# e.g., "SqlServerInstallation.SecuritySetup.SaPassword", "Pass@word1"
		[PSCredential]$DomainCredential,
		[string]$DomainCredsFromFile,
		[scriptblock]$DomainCredsLookup
	);
	
	begin {
		Validate-MethodUsage -MethodName "Map";
		
		[PSCredential]$internalDomainCreds = $null;
		
		# TODO: this sucks... assign these to an array and -notAny them... (actually ... i think $null -eq $array might even work... )
		if ((-not ($SecurityProvider)) -and (-not ($Secret)) -and (-not ($DomainCredential)) -and(-not($DomainCredsLookup))) {
			throw "Invalid Argument. Assign requires at least one parameter (e.g., -SecurityProvider, -Secret, or -DomainCredential) be provided.";
		}
		
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
			
			if (-not (Test-DomainCredentials -DomainCreds $DomainCredential)) {
				throw "Invalid Domain Credentials - failed to authenticate. ";
			}
			
			$internalDomainCreds = $DomainCredential;
		}
		
		# Load domainCreds from file and assign as creds: 
		if ($DomainCredsFromFile) {
			throw "Not yet Implemented.";
			
			#$internalDomainCreds = "loaded from file... ";
		}
	};
	
	process {
		
		if ($SecurityProvider){
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
		
		if ($Secret){
			try {
				$PVConfig.SetValue($Secret.Key, $Secret.Value);
			}
			catch {
				throw "EXCEPTION while setting -ConfigSecret within [Assign]: $_  `r$($_.ScriptStackTrace) ";
			}
		}
		
		if ($internalDomainCreds){
			$PVDomainCreds.SetCredential($internalDomainCreds);
		}
		
		if ($DomainCredsLookup){
			throw "Not yet implemented... ";
		}
	};
	
	end {
		
	};
}