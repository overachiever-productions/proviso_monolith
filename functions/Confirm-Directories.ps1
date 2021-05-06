Set-StrictMode -Version 1.0;

function Confirm-Directories {
	
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
		$expectedDirectories = $ServerDefinition.ExpectedDirectories;
		
		# Determine if SQL Server has been installed YET (i.e., this function might be running within the scope of provisioning a new server, or confirming ephemeral disks/directories/etc.)
		$sqlInstanceName = $expectedDirectories.SqlServerInstanceName;
		if ($sqlInstanceName -eq $null) {
			$sqlInstanceName = "MSSQLSERVER";
		}
		
		[string[]]$availableInstances = Get-InstalledSqlServerInstanceNames;
		$sqlInstalled = $false;
		if ($availableInstances -contains $sqlInstanceName) {
			$sqlInstalled = $true;
			
			$sqlServiceName = "NT SERVICE\MSSQLSERVER";
			
			if ($sqlInstanceName -ne "MSSQLSERVER") {
				# use a named-instance virtual service account:
				$sqlServiceName = "NT SERVICE\MSSQL$" + $sqlInstanceName;
			}
		}
		
		# Create SQL-Accessible Directories if they don't exist - and, if SQL Server is installed, grant SQL Server perms:
		foreach ($sqlAccessibleDirectory in $expectedDirectories.VirtualSqlServerServiceAccessibleDirectories) {
			
			Mount-Directory -Path $sqlAccessibleDirectory;
			if ($sqlInstalled) {
				Grant-SqlServicePermissionsToDirectory -TargetDirectory $sqlAccessibleDirectory -SqlServiceAccountName $sqlServiceName;
			}
		}
		
		# Create all Target Directories if they don't already exist:
		foreach ($directory in $expectedDirectories.RawDirectories) {
			Mount-Directory -Path $directory;
		}
	}
	
	end {
		
	}
}