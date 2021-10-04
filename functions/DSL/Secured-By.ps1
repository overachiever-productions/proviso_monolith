Set-StrictMode -Version 1.0;

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

function Secured-By {
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[System.Object]$Provider,
		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[PSCustomObject]$Config
		# vNEXT: Possible [Switch] for 'Strict' or 'StrongMatch' - i.e., OPTIONALLY throw if a key/value is sent in that doesn't exist in the $Config
	);
	
	begin {
		Limit-ValidProvisoDSL -MethodName "Secured-By";
		
		# verify memember-methods ([.LoadValues], .HasDomainCreds, .GetValues, [.GetCredentials])
		if (-not ($Provider.PSObject.Properties.Name -eq "HasDomainCreds")) {
			throw "SecretProvider does not implement or provide Property [HasDomainCreds].";
		}
		
		if (-not ($Provider.PSObject.Methods.Name -eq "GetValues")) {
			throw "SecretProvider does not implement or provider ScriptFunction [GetValues].";
		}
	}
	
	process {
		
		if ($Provider.PSObject.Methods.Name -eq "LoadValues") {
			try {
				$Provider.LoadValues();
			}
			catch {
				throw "EXCEPTION Executing .LoadValues against SecretProvider: $_ `r$($_.ScriptStackTrace) ";
			}
		}
		
		$secrets = $null;
		try {
			[System.Collections.Hashtable]$secrets = $Provider.GetValues();
		}
		catch {
			throw "SecretProvider's [GetValues] ScriptFunction does not return a [HashTable].";
		}
		
		try {
			foreach ($key in $secrets.Keys) {
				$value = $secrets[$key];
				
				$Config.SetValue($key, $value);
			}
		}
		catch {
			throw "EXCEPTION Setting Secured Config Values: $_  `r$($_.ScriptStackTrace) ";
		}
	}
	
	end {
		return $Config; # which is now 'enriched' with secured data.
	}
}

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