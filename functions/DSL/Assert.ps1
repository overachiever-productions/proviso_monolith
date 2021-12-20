Set-StrictMode -Version 1.0;

function Assert {
	param (
		[Parameter(Position = 0)]
		[string]$Description,
		[Parameter(Position = 1)]
		[ScriptBlock]$AssertBlock,
		[Alias("Has","For","Exists")]
		[Switch]$Is = $false,
		[Alias("HasNot", "DoesNotExist")]
		[Switch]$IsNot = $false,
		[string]$FailureMessage = $null,
		[Alias("NotFatal", "UnFatal", "Informal", "")]
		[Switch]$NonFatal = $false,
		[Alias("Skip", "DoNotRun")]
		[Switch]$Ignored = $false
	);
	
	begin {
		Validate-FacetBlockUsage -BlockName "Assert";
		
		if ($Is -and $IsNot) {
			# vNEXT: look at using $MyInvocation and/or other meta-data to determine WHICH alias was used and throw with those terms vs generic -Is/-IsNot:
			throw "The switches -Is (and aliases -Has, -For, -Exists) cannot be used concurrently with -IsNot (or aliases -HasNot, -DoesNotExist). An Assert is either true or false.";
		}
		
		[bool]$isNegated = $false;
		if ($IsNot) {
			$isNegated = $true;
		}
	}
	
	process {
		if ($Ignored) {
			return;
		}
		
		try{
			$assertion = New-Object Proviso.Models.Assertion($Description, $Name, $AssertBlock, $FailureMessage, $NonFatal, $Ignored, $isNegated);
		}
		catch {
			throw "Invalid Assert. `rException: $_ `r`t$($_.ScriptStackTrace)";
		}
	}
	
	end {
		if (-not ($Ignored)) {
			$facet.AddAssertion($assertion);
		}
	}
}