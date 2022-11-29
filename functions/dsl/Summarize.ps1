Set-StrictMode -Version 1.0;


<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Map -ProvisoRoot "\\storage\Lab\proviso\";
	Target -ConfigFile "\\storage\lab\proviso\definitions\PRO\PRO-197.psd1" -Strict:$false;

	Validate-TestingSurface;
	Configure-TestingSurface;
	Validate-WindowsPreferences;

	#Summarize -Last 3;
	Summarize -All;

#>

function Summarize {
	
	param (
#		[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
#		[Proviso.Processing.SurfaceProcessingResult[]]$ProcessingResults,
		[switch]$All = $false,
		[Parameter(ParameterSetName = "LastAsInt")]
		[int]$Last = 1,								# See: https://overachieverllc.atlassian.net/browse/PRO-234
		[switch]$LatestRunbook, 
		[switch]$IncludeSurfaceHeader = $true,
		[switch]$IncludeAssertions = $false,
		[switch]$IncludeAllValidations = $false,  	# by default, don't show validations for Configure operations - that info gets displayed in ... Configuration Summaries.
		[switch]$Terse = $false 					# keep tables/outputs to SINGLE line (vs 'non-terse' - where outcomes, etc. can contain multi-line info/outputs).
	);
	
	begin {
		[Proviso.Processing.SurfaceProcessingResult[]]$targets = $null;
		
		if ($null -eq $targets) {
			if ($All) {
				$targets = $PVContext.GetAllResults();
			}
			elseif ($Last) {
				$targets = $PVContext.GetLatestResults($Last);
			}
			
			if ($LatestRunbook) {
				$targets = $PVContext.GetLatestRunbookResults();
			}
		}
		
		# TODO might want to add an orthography check here... 
		if (($null -eq $targets) -or ($targets.Count -lt 1)) {
			throw "Invalid Operation. No Surface Processing Results were loaded to Summarize. Make sure to process results before executing Summarize.";
		}
	};
	
	process {
		
		[Proviso.Processing.AssertionResult[]]$asserts = @();
		[Proviso.Processing.ValidationResult[]]$validations = @();
		[Proviso.Processing.ConfigurationResult[]]$configurations = @();
		[Proviso.Processing.RebaseResult[]]$rebases = @();
		
		$Formatter.ResetSurfaceIds(); # resets SurfaceID functionality for this 'batch' of Summarize results... 
		foreach ($result in ($targets | Sort-Object -Property ProcessingStart )) {
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
		if ($IncludeSurfaceHeader) {
			"------------------------------------------------------------------------------------------------------------------------";
			"SURFACE PROCESSING SUMMARIES:";
			
			$targets | Sort-Object -Property ProcessingStart | Format-Table -View Surface-Summary -Wrap:(-not $Terse);
		}
		
		# yeah... this logic is kind of odd... but the idea is to show assertion outcomes IF they set via -IncludeAssertions OR... if there was a critical failure of an assertion in 1 or more Surfaces... 
		if ($IncludeAssertions -or $asserts.Count -gt 0) {
			if ($asserts.Count -gt 0) {
				"------------------------------------------------------------------------------------------------------------------------";
				"ASSERTION SUMMARIES:";
				$asserts | Format-Table -View Assertion-Summary -Wrap:(-not $Terse);
			}
			else {
				"------------------------------------------------------------------------------------------------------------------------";
				"NO ASSERTIONS.";
			}
		}
		
		if ($validations.Count -gt 0) {
			"------------------------------------------------------------------------------------------------------------------------";
			"VALIDATION SUMMARIES:";
			$validations | Format-Table -View Validation-Summary -Wrap:(-not $Terse);
		}
		
		if ($rebases.Count -gt 0){
			"------------------------------------------------------------------------------------------------------------------------";
			"REBASE SUMMARIES:";
			$rebases | Format-Table -View Rebase-Summary -Wrap:(-not $Terse);
		}
		
		if ($configurations.Count -gt 0) {
			"------------------------------------------------------------------------------------------------------------------------";
			"CONFIGURATION SUMMARIES:";
			$configurations | Format-Table -View Configuration-Summary -Wrap:(-not $Terse);
		}
		
		"------------------------------------------------------------------------------------------------------------------------";
	};
	
	end {
		
	};
}

