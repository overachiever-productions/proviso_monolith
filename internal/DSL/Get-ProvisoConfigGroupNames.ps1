Set-StrictMode -Version 1.0;

function Get-ProvisoConfigGroupNames {
	
	param (
		[Parameter(Mandatory)]
		[PSCustomObject]$Config,
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$GroupKey,
		[string]$OrderByKey
	);
	
	begin {
		# do validations/etc. 
	};
	
	process {
		$block = Get-ProvisoConfigValueByKey -Config $Config -Key $GroupKey;
		$keys = $block.Keys;
		
		if ($OrderByKey) {
			
			$prioritizedKeys = New-Object "System.Collections.Generic.SortedDictionary[int, string]";
			
			foreach ($key in $keys) {
				$orderingKey = "$GroupKey.$key.$OrderByKey";
				$priority = Get-ProvisoConfigValueByKey -Key $orderingKey -Config $Config;
				
				$prioritizedKeys.Add($priority, $key);
			}
			
			$keys = @();
			foreach ($orderedKey in $prioritizedKeys.GetEnumerator()) {
				$keys += $orderedKey.Value;
			}
		}
	};
	
	end {
		return $keys;
	};
}