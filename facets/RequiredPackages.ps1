Set-StrictMode -Version 1.0;

# . ..\functions\DSL\Facet.ps1

Facet "RequiredPackages" {
	
	Assertions {
		Assert "Executing as Administrator." {
			$x = "this is a script block";
		}
		Assert "Windows Server Edition" {
			$y = "so is this";
		}
	}
	
	Definitions {
		Definition "Wsfc Installed" {
			$y = "pretend this is a script";
		}
		
		Definition "NetFx For Pre-2016 Instances" {
			$y = "this too....";
		}
	}
}