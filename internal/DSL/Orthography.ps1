Set-StrictMode -Version 1.0;

$script:ProvisoOrthography = [Proviso.Orthography]::Instance;

Filter Validate-MethodUsage {
	param (
		[Parameter(Mandatory)]
		[string]$MethodName
	);
	
	$dslError = $ProvisoOrthography.AddDslMethod($MethodName);
	
	if ($dslError) {
		throw $dslError;
	}
}

Filter Validate-SurfaceBlockUsage {
	param (
		[Parameter(Mandatory)]
		[string]$BlockName
	);
	
	$dslError = $ProvisoOrthography.AddSurfaceBlock($BlockName);
	
	if ($dslError) {
		throw $dslError;
	}
}