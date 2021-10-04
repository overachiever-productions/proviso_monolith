Set-StrictMode -Version 1.0;

function Invoke {
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$ProcesBlock,
		[switch]$ContinueOnException = $false
	);
	
	begin {
		Limit-ValidProvisoDSL -MethodName "Invoke";
	};
	
	process {
		# this 'method' is much different than the others which are simple 'wrappers' for [scriptblock]s. 
		#  instead, this will need to PARSE (probably using the .ast) the code block, 
		#  	and
		# 		foreach(line)   (where line = clrf or ; )
		# 			if the line isn't a comment and/or isn't commented-out
		# 				add it to a list of 'Facets' to process (in order)
		
		#   then, once we've got our 'list of facets' to process: 
		# 		create an output object (i.e., array of FacetProcessingOutput objects... )
		# 			and... for each facet in the list: 
		# 				run it
		# 					handle try/catch outcomes
		# 				assign outputs into the array of outputs
		# 				and terminate if !-ContinueOnException
		# 				otherwise, run until the end... and spit out the array of outputs.
	}; 
	
	end {
		
	};
}