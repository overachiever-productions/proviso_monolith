Set-StrictMode -Version 1.0;

function Resolve-SqlServerBuildVersionFromMdf {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$FullFilePathAndNamePlusExtension
	);
	
	begin {
		
	};
	
	process {
		# Dope: http://rusanu.com/2011/04/04/how-to-determine-the-database-version-of-an-mdf-file/
		
		$info = Get-Content -AsByteStream $FullFilePathAndNamePlusExtension | Select-Object -Skip 0x12064 -First 2;
		[int]$base = [int]$info[1] * 256;
		[int]$final = $base + [int]$info[0];
		
		# https://sqlserverbuilds.blogspot.com/2014/01/sql-server-internal-database-versions.html
		return $final;
	};
	
	end {
		
	};
}