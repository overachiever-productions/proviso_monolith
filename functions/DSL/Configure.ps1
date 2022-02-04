Set-StrictMode -Version 1.0;

function Configure {
	param (
		[ScriptBlock]$ConfigureBlock
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Configure";
		
		if ($UsesBuild) {
			throw "Invalid Argument. Facets can use EITHER a Configure{} block OR the -UsesBuild parameter (not both).";
		}
	}
	
	process {
		$facet.SetConfigure($ConfigureBlock);
	}
	
	end {
		
	}
	
}