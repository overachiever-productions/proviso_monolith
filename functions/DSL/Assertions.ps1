Set-StrictMode -Version 1.0;

function Assertions {
	param (
		[ScriptBlock]$Assertions
	);
	
	Limit-ValidProvisoDSL -MethodName "Assertions" -AsFacet;
	
	# vNEXT: figure out how to constrain inputs here - as per: https://powershellexplained.com/2017-03-13-Powershell-DSL-design-patterns/#restricted-dsl
	# 		oddly, I can't use a ScriptBlock literal here - i.e., i THINK I could use a string, but not a block... so, MAYBE? convert the block to a string then 'import' it that way to ensure it's constrained?
	#			$validatedAssertions = [ScriptBlock]::Create("DATA -SupportedCommand Assert {$Assertions}");
	#			& $validatedAssertions
	& $Assertions;
}