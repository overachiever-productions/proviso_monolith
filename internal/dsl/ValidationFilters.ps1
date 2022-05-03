Set-StrictMode -Version 1.0;

$script:ProvisoOrthography = [Proviso.Orthography]::Instance;
filter Validate-MethodUsage {
	param (
		[Parameter(Mandatory)]
		[string]$MethodName
	);
	
	$dslError = $ProvisoOrthography.AddDslMethod($MethodName);
	
	if ($dslError) {
		throw $dslError;
	}
}

filter Validate-SurfaceBlockUsage {
	param (
		[Parameter(Mandatory)]
		[string]$BlockName
	);
	
	$dslError = $ProvisoOrthography.AddSurfaceBlock($BlockName);
	
	if ($dslError) {
		throw $dslError;
	}
}

filter Validate-Config {
	
	if ($null -eq $PVConfig) {
		throw "Invalid Operation. `$PVConfig has not been set yet - or is `$null. Please ensure that [With] has been executed to defined a configuration block for processing needs.";
	}
}

filter Validate-RunbookProcessing {
	if ($null -eq $PVContext.CurrentRunbook) {
		throw "Invalid Operation. Runbook related operations (Evaluate, Provision, Document) can only be accessed when a Runbook is being processed.";
	}
}