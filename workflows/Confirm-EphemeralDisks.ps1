Set-StrictMode -Version 1.0;

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