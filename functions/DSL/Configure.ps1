Set-StrictMode -Version 1.0;

function Configure {
	param (
		[ScriptBlock]$ConfigureBlock
	);
	
	begin {
		Validate-FacetBlockUsage -BlockName "Configure";
		
		if ($ConfiguredBy) {
			throw "Invalid Argument. Define blocks can use EITHER a Configure{} block OR the -ConfiguredBy parameter (not both).";
		}
	}
	
	process {
		$definition.SetConfigure($ConfigureBlock);
	}
	
	end {
		
	}
	
}