Set-StrictMode -Version 1.0;


<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	
	With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1" | Configure-TestingFacet;

	Summarize -All #-IncludeAssertions;

#>

function Summarize {
	
	param (
		[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[Proviso.Processing.FacetProcessingResult[]]$ProcessingResults,
		[switch]$All = $false,
		[switch]$Terse = $false,  # keep tables/outputs to SINGLE line (vs 'non-terse' - where outcomes, etc. can contain multi-line info/outputs).
		# vNEXT: there SHOULD be a way to only/just use 'Last' - as in, check to see if it's an arg... if it is, it can EITHER be a 'switch' (i.e., value of 1 if no [int] value specified) OR an int... 
		# Or... just figure out a better way to distinguis between 'last' and LastN, hell, might even be as simple as -Last and -LastN (or ... -Last and -Lastest)
		[switch]$Latest = $false,
		[int]$Last = $null,
		[switch]$IncludeFacetHeader = $true,
		[switch]$IncludeAssertions = $false,
		[switch]$IncludeAllValidations = $false  # by default, don't show validations for Configure operations - that info gets displayed in ... Configuration Summaries.
	);
	
	begin {
		[Proviso.Processing.FacetProcessingResult[]]$targets = $ProcessingResults;
		
		if ($null -eq $targets) {
			if ($All) {
				$targets = $PVContext.GetAllResults();
			}
			else {
				if ($Latest) {
					$targets = @($PVContext.LastProcessingResult);
				}
				else {
					$targets = $PVContext.GetLatestResults($Last);
				}
			}
		}
	};
	
	process {
		
		[Proviso.Processing.AssertionResult[]]$asserts = @();
		[Proviso.Processing.ValidationResult[]]$validations = @();
		[Proviso.Processing.ConfigurationResult[]]$configurations = @();
		[Proviso.Processing.RebaseResult[]]$rebases = @();
		
		foreach ($result in $targets) {
			
			if ($IncludeAssertions -or ($result.AssertionsFailed)) {
				foreach ($assert in $result.AssertionResults) {
					$asserts += $assert;
				}
			}
			
			foreach ($validation in $result.ValidationResults) {
				
				# only output/display ValidationResults IF -IncludeAllValidations OR the operation is a Validation (only). 
				if ($IncludeAllValidations) {
					$validations += $validation;
				}
				else {
					if (-not $result.ExecuteConfiguration) {
						$validations += $validation;
					}
				}
			}
		
			foreach ($configuration in $result.ConfigurationResults) {
				$configurations += $configuration;
			}
			
			# TODO: probably makes more sense to look for specific RebaseOutcomes (i.e., OTHER than UnProcessed) - just incase a rebase STARTS but crashes/fails? (Er, well, actually: the try/catch in rebase should catch any problems....)
			if ($null -ne $result.RebaseResult) {
				$rebases += $result.RebaseResult;
			}
		}
		
		# Emit results into console/output:
		if ($IncludeFacetHeader) {
			"-------------------------------------------------------------------------------------------------------------------------------";
			"FACET PROCESSING SUMMARIES:";
			
			$targets | Format-Table -View Facet-Summary -Wrap:(-not $Terse);
		}
		
		# yeah... this logic is kind of odd... but the idea is to show assertion outcomes IF they set via -IncludeAssertions OR... if there was a critical failure of an assertion in 1 or more Facets... 
		if ($IncludeAssertions -or $asserts.Count -gt 0) {
			if ($asserts.Count -gt 0) {
				"-------------------------------------------------------------------------------------------------------------------------------";
				"ASSERTION SUMMARIES:";
				$asserts | Format-Table -View Assertion-Summary -Wrap:(-not $Terse);
			}
			else {
				"-------------------------------------------------------------------------------------------------------------------------------";
				"NO ASSERTIONS.";
			}
		}
		
		if ($validations.Count -gt 0) {
			"-------------------------------------------------------------------------------------------------------------------------------";
			"VALIDATION SUMMARIES:";
			$validations | Format-Table -View Validation-Summary -Wrap:(-not $Terse);
		}
		
		if ($rebases.Count -gt 0){
			"-------------------------------------------------------------------------------------------------------------------------------";
			"REBASE SUMMARIES:";
			$rebases | Format-Table -View Rebase-Summary -Wrap:(-not $Terse);
		}
		
		if ($configurations.Count -gt 0) {
			"-------------------------------------------------------------------------------------------------------------------------------";
			"CONFIGURATION SUMMARIES:";
			$configurations | Format-Table -View Configuration-Summary -Wrap:(-not $Terse);
		}
		
		"-------------------------------------------------------------------------------------------------------------------------------";
	};
	
	end {
		
	};
}