Set-StrictMode -Version 1.0;

function Compare-ExpectedWithActual {
	param (
		[Parameter(Mandatory)]
		$Expected,
		[Parameter(Mandatory)]
		[ScriptBlock]$TestBlock
	);
	
	begin {
		
	};
	
	process {
		
		#region vNEXT
		# vNEXT: Look into using Compare-Object. 
		# 		it's super powerful/complex  ... but, might make sense to verify that 'all' details/outputs were == 
		# 		and potentially capture those that don't ==.
		#endregion	
		
		$actualResult = $null;
		$actualException = $null;
		try {
			$actualResult = & $TestBlock;
		}
		catch {
			$actualException = $_;
		}
		
		[bool]$comparedValuesMatch = $false;
		
		[System.Management.Automation.ErrorRecord]$comparisonError = $null;
		if ($null -eq $actualException) {
			
			try {
				$comparedValuesMatch = ($Expected -eq $actualResult);
			}
			catch {
				$comparisonError = $_;
			}
		}
#		else{
#			try {
#				# yeah... this is a hell of a way to do this... 
#				throw "Cannot compare Expected vs Actual because one or more of the evaluation operations for Expected/Test threw an exception.";
#			}
#			catch {
#				$comparisonError = $_;
#			}
#		}
		
	};
	
	end {
		$output = [PSCustomObject]@{
			'ActualResult' = $actualResult
			'ActualError' = $actualException
			'Matched' = $comparedValuesMatch
			'ComparisonError' = $comparisonError
		};
		
		return $output;
	};
}

## Example of a set of Tests:
#[System.Management.Automation.ScriptBlock]$test = {
#	$domain = (Get-CimInstance Win32_ComputerSystem).Domain;
#	if ($domain -eq "WORKGROUP") {
#		$domain = "";
#	}
#	# TODO: "" (when 'domain' -eq WORKGROUP) and "" from the $Config.Host.TargetDomain ... aren't matching. THEY SHOULD BE... 
#	# 		that's the whole purpose of the if(is-string) & if(empty)... inside of Compare-ExpectedWithActual.ps1;
#	return $domain; # ruh roh... it MIGHT be the return?
#};
#
#[scriptblock]$expected = {
#	$Config.GetValue("Host.TargetDomain");
#};
#
#Add-Type -Path .\..\..\classes\DslStack.cs;
#. .\Limit-ValidProvisoDSL.ps1;
#. .\DslStack.ps1;
#. .\..\..\functions\DSL\With.ps1;
#. .\Get-ProvisoConfigDefault.ps1;
#. .\Get-ProvisoConfigValueByKey.ps1;
#
#$Config = With "\\storage\Lab\proviso\definitions\servers\S4\SQL-120-01.psd1";
#$x = Compare-ExpectedWithActual -ExpectedBlock $expected -TestBlock $test;
#Write-Host $x.Matched;