Set-StrictMode -Version 1.0;

filter Limit-ValidProvisoDSL {
	param (
		[Parameter(Mandatory)]
		[string]$MethodName,
		[switch]$AsFacet = $false
	);
	
	$stack = $ProvisoDslStack;
	
	$dslError = "";
	if ($AsFacet) {
		$dslError = $stack.AddFacetBlock($MethodName);
	}
	else {
		$dslError = $stack.AddDslMethod($MethodName);
	}
	
	if ($dslError) {
		throw $dslError;
	}
}