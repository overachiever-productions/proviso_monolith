Set-StrictMode -Version 1.0;

function Get-ProvisoConfigGroupNames {
	
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$Config,
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$GroupKey
		
	);
	
	begin {
		# do validations/etc. 
	};
	
	process {
		$block = Get-ProvisoConfigValueByKey -Config $Config -Key $GroupKey;
		$keys = $block.Keys;
	};
	
	end {
		return $keys;
	};
}