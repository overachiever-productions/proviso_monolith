Set-StrictMode -Version 1.0;

# TODO: maybe look at creating multiple config-secrets or -ConfigSecret_S_ as a param?

function Assign {
	
	param (
		[string]$ProvisoRoot,
		[System.Object]$SecurityProvider,
		[PSCustomObject]$ConfigSecret, 					# e.g., "SqlServerInstallation.SecuritySetup.SaPassword", "Pass@word1"
		[PSCredential]$DomainCredential,
		[string]$DomainCredsFromFile,
		[scriptblock]$DomainCredsLookup
	);
	
	begin {
		Validate-MethodUsage -MethodName "Assign";
		
		[PSCredential]$internalDomainCreds = $null;
		
		# TODO: this sucks... assign these to an array and -notAny them... (actually ... i think $null -eq $array might even work... )
		if ((-not ($SecurityProvider)) -and (-not ($ConfigSecret)) -and (-not ($DomainCredential)) -and(-not($ProvisoRoot)) -and(-not($DomainCredsLookup))) {
			throw "Invalid Argument. Assign requires at least one parameter (e.g., -SecurityProvider, -Secret, or -DomainCredential) be provided.";
		}
		
		if ($ProvisoRoot) {
			if (-not (Test-Path $ProvisoRoot)) {
				throw "Invalid -ProvisoRoot value provided to [Assign]. Path NOT found or does not exist.";
			}
		}
		
		if ($ConfigSecret) {
			if ($ConfigSecret.Count -ne 1) {
				throw "Invalid Argument. A -ConfigSecret can only represent a single key/value combination.";
			}
			
			# verify that the KEY is legit/valid:
			$key = $ConfigSecret.Key;
			
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
		
		if ($ProvisoRoot) {
			$PVResources.SetRoot($ProvisoRoot);
		}
		
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
		
		if ($ConfigSecret){
			try {
				$PVConfig.SetValue($ConfigSecret.Key, $ConfigSecret.Value);
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


#####################################################################################################
# NOTE: Old 'Secured-By' implementation is listed below (along with all notes/etc)... 



<#
	SCOPE: 
		SecretsProviders are not to HIDE secure details from Proviso or users (Proviso will typically be run by Admins/elevated-priv-users)
		Instead, SecretProviders assist in preventing sensitive information from being stored within config-files or other easily-accessible areas.

		Members
			OPTIONAL bool .HasDomainCreds 
			OPTIONAL PSCredentials .GetCredentials() 
			OPTIONAL void .LoadValues()  (allows optional 'load' or 'get' mechanisms like decrypt or execute web-service lookups/etc. 
			[Hashtable] .GetValues() ... 
	
	vNEXT: 
		Secured-By currently executes .LoadValues() (if present), to get/decrypt/whatever ALL values via .GetValues(). 
			it then overwrites any matches against the $Config - meaning that this is all a rather 'static' operation. 
			vNEXT... I'd like Secured-By to 'tell' $Config that $keyX, $keyY, etc. are 'secured'. 
				at which point, when it ($Config) goes to look up/get a value, it 'knows' that the key is secured... 
					and asks the PROVIDER for the value ('just in time') for a more secure approach to managing secrets. 
#>



<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;

	# ultra-bare-bones/simple 'provider' implementation:
	[PSCustomObject]$Provider = {
	};

	[ScriptBlock]$getValues = {
		[System.Collections.Hashtable]$values = @{
			"SqlServerInstallation.SecuritySetup.SaPassword" = "Pass@word1!!!!"
			"AdminDb.DatabaseMail.SmtpPassword"			     = "super secret password!"
		};
		
		return $values;
	}
	[ScriptBlock]$getCreds = {
		throw "Not Implemented";
	}

	Add-Member -InputObject $Provider -MemberType NoteProperty -Name HasDomainCreds -Value $false;
	Add-Member -InputObject $Provider -MemberType ScriptMethod -Name GetValues -Value $getValues;
	Add-Member -InputObject $Provider -MemberType ScriptMethod -Name GetCredentials -Value $getCreds;
	# end implementation.

	With "D:\Dropbox\Desktop\S4 - New\SQL-120-01.psd1" | Secured-By $Provider | Validate-FirewallRules;

	Summarize -All;

#>


			#
			#function Secured-By {
			#	param (
			#		[Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
			#		[System.Object]$Provider,
			#		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
			#		[PSCustomObject]$Config
			#		# vNEXT: Possible [Switch] for 'Strict' or 'StrongMatch' - i.e., OPTIONALLY throw if a key/value is sent in that doesn't exist in the $Config
			#	);
			#	
			#	begin {
			#		Validate-MethodUsage -MethodName "Secured-By";
			#		
			#		# verify memember-methods ([.LoadValues], .HasDomainCreds, .GetValues, [.GetCredentials])
			#		if (-not ($Provider.PSObject.Properties.Name -eq "HasDomainCreds")) {
			#			throw "SecretProvider does not implement or provide Property [HasDomainCreds].";
			#		}
			#		
			#		if (-not ($Provider.PSObject.Methods.Name -eq "GetValues")) {
			#			throw "SecretProvider does not implement or provider ScriptFunction [GetValues].";
			#		}
			#	}
			#	
			#	process {
			#		
			#		if ($Provider.PSObject.Methods.Name -eq "LoadValues") {
			#			try {
			#				$Provider.LoadValues();
			#			}
			#			catch {
			#				throw "EXCEPTION Executing .LoadValues against SecretProvider: $_ `r$($_.ScriptStackTrace) ";
			#			}
			#		}
			#		
			#		$secrets = $null;
			#		try {
			#			[System.Collections.Hashtable]$secrets = $Provider.GetValues();
			#		}
			#		catch {
			#			throw "SecretProvider's [GetValues] ScriptFunction does not return a [HashTable].";
			#		}
			#		
			#		try {
			#			foreach ($key in $secrets.Keys) {
			#				$value = $secrets[$key];
			#				
			#				$Config.SetValue($key, $value);
			#			}
			#		}
			#		catch {
			#			throw "EXCEPTION Setting Secured Config Values: $_  `r$($_.ScriptStackTrace) ";
			#		}
			#	}
			#	
			#	end {
			#		return $Config; # which is now 'enriched' with secured data.
			#	}
			#}

#
## Testing:
#
#. .\With.ps1;
#. ..\..\internal\DSL\Limit-ValidProvisoDSL.ps1;
#. ..\..\internal\DSL\Get-ProvisoConfigValueByKey.ps1;
#. ..\..\internal\DSL\Set-ProvisoConfigValueByKey.ps1;
#Add-Type -Path "D:\Dropbox\Repositories\proviso\classes\DslStack.cs";
#$script:provisoDslStack = [Proviso.Models.DslStack]::Instance;
#
##  ultra-bare-bones/simple 'provider' implementation:
#[PSCustomObject]$Provider = {
#};
#
#[ScriptBlock]$getValues = {
#	[System.Collections.Hashtable]$values = @{
#		"SqlServerInstallation.SecuritySetup.SaPassword" = "Pass@word1!!!!"
#		"AdminDb.DatabaseMail.SmtpPassword"			     = "super secret password!"
#	};
#	
#	return $values;
#}
#[ScriptBlock]$getCreds = {
#	throw "Not Implemented";
#}
#
#Add-Member -InputObject $Provider -MemberType NoteProperty -Name HasDomainCreds -Value $false;
#Add-Member -InputObject $Provider -MemberType ScriptMethod -Name GetValues -Value $getValues;
#Add-Member -InputObject $Provider -MemberType ScriptMethod -Name GetCredentials -Value $getCreds;
## end implementation.
#
#$x = With "\\storage\Lab\proviso\definitions\servers\S4\SQL-120-01.psd1" | Secured-By $Provider;
#$x.GetValue("SqlServerInstallation.SecuritySetup.SaPassword");