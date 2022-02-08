Set-StrictMode -Version 1.0;

function Assign {
	[Alias("Define")]
	
	param (
		[string]$ProvisoRoot
		# TODO: Proviso(User)Config
		# TODO: Proviso Options... 
	);
	
	begin {
		if ($ProvisoRoot) {
			if (-not (Test-Path $ProvisoRoot)) {
				throw "Invalid -ProvisoRoot value provided to [Assign]. Path NOT found or does not exist.";
			}
		}
		else {
			#TODO: attempt to set from C:\Scripts or C:\Scripts\Proviso
			throw "Proviso Framework Error. -ProvisoRoot is CURRENTLY a required argument.";
		}
	};
	
	process {
		if ($ProvisoRoot) {
			$PVResources.SetRoot($ProvisoRoot);
		}
	};
	
	end {
		
	};
}