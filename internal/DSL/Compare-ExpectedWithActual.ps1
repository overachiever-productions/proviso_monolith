Set-StrictMode -Version 1.0;

function Compare-ExpectedWithActual {
	param (
		[Parameter(Mandatory)]
		$Expected,
		[Parameter(Mandatory)]
		$Actual
	);
	
	begin {
		if (($Expected.GetType().Name) -eq 'String') {
			if ([string]::IsNullOrEmpty($Expected)){
				$Expected = $null;
			}
		}
		if (($Actual.GetType().Name) -eq 'String') {
			if ([string]::IsNullOrEmpty($Actual)) {
				$Actual = $null;
			}
		}
	};
	
	process {
		
		#region vNEXT
		# vNEXT: Look into using Compare-Object. 
		# 		it's super powerful/complex  ... but, might make sense to verify that 'all' details/outputs were == 
		# 		and potentially capture those that don't ==.
		#endregion	
		
		[bool]$comparedValuesMatch = $false;
		[System.Management.Automation.ErrorRecord]$comparisonError = $null;
		try{
			$comparedValuesMatch = ($expectedResult -eq $actualResult);
		}
		catch {
			$comparisonError = $_;
		}
	};
	
	end {
		$output = [PSCustomObject]@{
			'Match' = $comparedValuesMatch
			'Error' = $comparisonError
		};
		
		return $output;
	};
}