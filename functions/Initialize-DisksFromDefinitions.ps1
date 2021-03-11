Set-StrictMode -Version 1.0;

function Initialize-DisksFromDefinitions {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$ServerDefinition,
		[Parameter(Mandatory = $true)]
		[string[]]$CurrentlyMountedVolumeLetters,
		[switch]$ProcessEphemeralDisksOnly = $true,
		[switch]$Strict = $true
	);
	
	begin {
		 # Verify Strict:
		if ($Strict) {
			$currentHostName = $env:COMPUTERNAME;
			if ($currentHostName -ne $ServerDefinition.TargetServer) {
				throw "HostName defined by -ServerDefinition [$($ServerDefinition.TargetServer)] does NOT match current server hostname [$currentHostName]. Processing Aborted."
			}
		}
	};
	
	process {
		
		# --------------------------------------------------------------------------------------
		# Address any Disks that haven't been initialized/mapped/etc:
		# --------------------------------------------------------------------------------------
		# TODO: this needs to be a prioritized list:
		$expectedDisks = Merge-AvailableDisksWithExpectedDiskIdentifiers -ServerDefinition $ServerDefinition -CurrentlyMountedVolumeLetters $CurrentlyMountedVolumeLetters;
		
		foreach ($key in $expectedDisks.Keys) {
			$disk = $expectedDisks[$key];
			
			# TODO: this seems pretty redundant - i.e., Merge-AvailableDisksWIth... etc... is always reporting IsProvisioned = $false. 
			# 		I THINK the idea here was that I'd ONLY provision disks IF they weren't found (then move on to working through ensuring directories/perms and the likes). 
			# 			but... can't really see howw I need this whole .IsProvisioned check at all at this point... 
			if (!($disk.IsProvisioned)) {
				
				if ($disk.MatchFound) {
					
					$diskNumber = $disk.MatchedPhysicalDisk.DiskNumber;
					$definedDisk = $ServerDefinition.ExpectedDisks[$disk.NameOfExpectedDisk];
					
					try {
						Initialize-TargetedDisk -DiskNumber $diskNumber -VolumeName $definedDisk.VolumeName -VolumeLabel $definedDisk.VolumeLabel;
					}
					catch {
						throw "Exception attempting to Initialize Disk $($disk.MatchedPhsycialDisk.DiskNumber) as $($definedDisk.VolumeName).";
					}
					
				}
				else {
					
					Write-Host "no match found?";
					
					if ($Strict) {
						throw "Expected Disk for $($definedDisk.VolumeName) not found - no matches available. Disk cannot be provisioned.";
					}
				}
			}
		}
		
		# --------------------------------------------------------------------------------------
		# Now that all disks should be configured/initialized, verify directories/perms/shares:
		# --------------------------------------------------------------------------------------
		
		# vNEXT: need to account for NON-default instances of SQL Server - i.e. shove something into the .psd1 file that tracks the InstanceName if/when it's other than MSSQLSERVER (or... can track that too... but, it's only really/truly needed IF we want to override.)
		# 		likewise, if/when that's overridden, assign perms to a virtual account OTHER than NT SERVICE\MSSQLSERVER.
		$sqlServerServiceExists = (Get-Service -Name "MSSQLSERVER" -ErrorAction SilentlyContinue) -ne $null;
		
		[string[]]$keys = $ServerDefinition.ExpectedDisks.Keys;
		foreach ($diskName in $keys) {
			
			# verify directories and perms:
			foreach ($directory in $disk.ExpectedDirectories.VirtualSqlServerServiceAccessibleDirectories) {
				Mount-Directory -Path $directory;
				
				if ($sqlServerServiceExists) {
					
					# TODO: what if perms already exist? does that throw an error and/or should we be checking for perms first anyhow? 
					# 		pretty sure the process is idempotent - i.e., if I add X perms to xyz dir for user Blah, and they already have those perms
					# 			i'm pretty sure that ... there's no problem or issue at all/etc. 
					Grant-SqlServicePermissionsToDirectory -TargetDirectory $directory;
				}
			}
			
			foreach ($directory in $disk.ExpectedDirectories.RawDirectories) {
				Mount-Directory -Path $directory;
			}
			
			# verify shares and perms:
			[string[]]$shareKeys = $disk.SharedDirectories.Keys;
			foreach ($shareKey in $shareKeys) {
				
				# If the share doesn't exist, create it. 
				
				
				$share = $disk.SharedDirectories.$shareKey;
				
				[string[]]$fullAccess = $share.ReadOnlyAccess;
				[string[]]$readAccess = $share.ReadWriteAccess;
				
				# NOTE: Granting Perms against the SHARE doesn't do anything at the FOLDER level - i.e., will need to grant perms against the directory too. 
				# NOTE: if either $fullAccess or $readAccess are emtpy arrays (i.e., @(), then New-SmbShare will throw exceptions - meaning I need to 
				#     		either set up if/else statements on which 'overload' of New-SmbShare to call based on what's populated, or look
				# 				into options for dynamically calling based on parameters. )
				#   				here's an option - i.e., build a 'string' and run Invoke-Function and/or &"string";
				# 							https://stackoverflow.com/questions/6847923/invoking-function-in-powershell-via-string
				# 						
				New-SmbShare -Name $share.ShareName -Path $share.SourceDirectory -FullAccess $fullAccess -ReadAccess $readAccess;
				
				# If perms aren't as expected, grant them. 
				
			}
		}
	};
	
	end {
		
	};
}