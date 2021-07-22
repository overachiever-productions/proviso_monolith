Set-StrictMode -Version 1.0;

<#
	outline/flow
		1. Bootstrap
			THINK I need to go with the assumption that Proviso is already INSTALLED - and that it just needs to be Imported. 
				i.e., slightly different bootstrap logic here... 
					this, of course, also means that we need to figure out how to get proviso installed via a 'profile' or available/accessible to SYSTEM or whatever will run
					the script when it executes at startup... 

		2. Determine Machine Name

		3. Run through disk's config (strict - of course) against Ephmeral Disks with the -EphemeralOnly:$true switch... 
		4. the end. 




#>



















# Example Invocation: > Confirm-EphemeralDisks -ConfigFilePath "C:\scripts\definitions\server-name-here_ephmeral_disks.psd1" -AttemptSqlRestart;

function Confirm-EphemeralDisks {
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$ConfigFilePath,
		[switch]$AttemptSqlRestart = $true
	);
	
	begin {
		[PSCustomObject]$ServerDefinition = Read-ServerDefinitions -Path $ConfigFilePath -Strict;
		
		$currentHostName = $env:COMPUTERNAME;
		if ($Strict) {
			if ($currentHostName -ne $ServerDefinition.TargetServer) {
				throw "HostName defined by $ServerDefinitionsPath [$($ServerDefinition.TargetServer)] does NOT match current server hostname [$currentHostName]. Processing Aborted."
			}
		}
	}
	
	process {
		
		$currentlyMountedVolumes = Get-ExistingVolumeLetters;
		
		# TODO: wrap the following directives in try/catch blocks. BUT, if errors happen, ATTEMPT to keep going... i.e., we ideally want NO errors, but services and 'such' are dependent upon as much of the configuration below happening as possible... so capture error details, hold them, move on to the next step, process it, and then report ALL errors at the end. 
		
		# TODO: wrap each call in a set of ShouldProcess logic ... 
		Confirm-DefinedDisks -ServerDefinition $ServerDefinition -MountedVolumes $currentlyMountedVolumes;
		
		# process directories / perms
		Confirm-Directories -ServerDefinition $ServerDefinition -Strict;
		
		# process shares /perms... 
		
		
		if ($AttemptSqlRestart) {
			# if sql is stopped, restart... 
		}
	}
	
	end {
		
	}
}