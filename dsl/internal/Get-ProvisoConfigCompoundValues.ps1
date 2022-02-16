Set-StrictMode -Version 1.0;

function Get-ProvisoConfigCompoundValues {
	
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$Config,
		[Parameter(Mandatory)]
		[string]$FullCompoundKey,
		[switch]$OrderDescending = $false
	);
	
	begin {
		
	}
	
	process {
		$keys = Get-ProvisoConfigValueByKey -Config $Config -Key $FullCompoundKey;
	}
	
	end {
		return $keys;
	}
}