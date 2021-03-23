Set-StrictMode -Version 1.0;

function Confirm-Shares {
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$ServerDefinition,
		[switch]$Strict = $true
	);
	
	begin {
		$currentHostName = $env:COMPUTERNAME;
		if ($Strict) {
			if ($currentHostName -ne $ServerDefinition.TargetServer) {
				throw "HostName defined by $ServerDefinitionsPath [$($ServerDefinition.TargetServer)] does NOT match current server hostname [$currentHostName]. Processing Aborted."
			}
		}
	}
	
	process {
		$expectedShares = $ServerDefinition.ExpectedShares;
		
		# verify shares and perms:
		[string[]]$shareKeys = $expectedShares.Keys;
		foreach ($shareKey in $shareKeys) {
			
			$shareDefinition = $expectedShares.$shareKey;
			[string]$shareName = $shareDefinition.ShareName;
			[string]$shareDirectory = $shareDefinition.SourceDirectory;
			
			#create directory (if it doesn't exist):
			Mount-Directory -Path $shareDirectory;
			
			# check to see if the share exists:			
			$share = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue;
			
			if ($share -eq $null) {
				New-SmbShare -Name $shareName -Path $shareDirectory;
			}
			
			# now that it's created - either 'just now', or previously, ensure access (which is idempotent)
			[string[]]$readAccess = $shareDefinition.ReadOnlyAccess;
			[string[]]$fullAccess = $shareDefinition.ReadWriteAccess;
			
			foreach ($reader in $readAccess) {
				Grant-SmbShareAccess -Name $shareName -AccountName $reader -AccessRight Read -Force;
			}
			
			foreach ($account in $fullAccess){
				Grant-SmbShareAccess -Name $shareName -AccountName $account -AccessRight Full -Force;
			}
		}
	}
	
	end {
		
	}
}