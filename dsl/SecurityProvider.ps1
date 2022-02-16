Set-StrictMode -Version 1.0;

<#
	SCOPE: 
		SecretsProviders are not to HIDE secure details from Proviso or users (Proviso will typically be run by Admins/elevated-priv-users)
		Instead, SecretProviders assist in preventing sensitive information from being stored within config-files or other easily-accessible areas.

		Members
			OPTIONAL void .LoadValues()  (allows optional 'load' or 'get' mechanisms like decrypt or execute web-service lookups/etc. 
			REQUIRED: [Hashtable] .GetValues() ... 
	
	vNEXT: 
		Secured-By currently executes .LoadValues() (if present), to get/decrypt/whatever ALL values via .GetValues(). 
			it then overwrites any matches against the $Config - meaning that this is all a rather 'static' operation. 
			vNEXT... I'd like Secured-By to 'tell' $Config that $keyX, $keyY, etc. are 'secured'. 
				at which point, when it ($Config) goes to look up/get a value, it 'knows' that the key is secured... 
					and asks the PROVIDER for the value ('just in time') for a more secure approach to managing secrets. 
#>

<#

	#Sample Usage: 

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;

	#ULTRA BARE-BONES implementation: 	
		[PSCustomObject]$Provider = {};

		[ScriptBlock]$getValues = {
			[System.Collections.Hashtable]$values = @{
				"SqlServerInstallation.SecuritySetup.SaPassword" = "Pass@word1!!!!"
				"AdminDb.DatabaseMail.SmtpPassword"			     = "super secret password!"
			};
			
			return $values;
		}

		Add-Member -InputObject $Provider -MemberType ScriptMethod -Name GetValues -Value $getValues;


	With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Assign -SecurityProvider $Provider;

#>

# TODO: implement a few different kinds of SecurityProviders here... e.g.
function FileBased-SecurityProvider {
	# return a [PSCustomObject] that meets interface needs and which pulled info from a file somewhere... 
}

function Interactive-SecurityProvider {
	# [PSCustomObject] with a .LoadValues() that, for each needed value... throws out a PROMPT with "provide xxxx for blah"... and then sets the values... 
}

function WebService-SecurityProvider {
	# with .LoadValues() that zips out to a web service or something and grabs creds as needed.... 
}

# probably: 
function Static-SecurityProvider {
	# lets a user spam in all sorts of values via canned -arguments like -SaPassword, -Something, -AnotherSecret, -AndSoOn... 
	#  and ... use a -Strict/-Force/-AllSomething switch to determine if ANY of the values/inputs above can be NULL or not... 
}