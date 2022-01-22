Set-StrictMode -Version 1.0;

Facet AdminDbBackups {
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	Group-Definitions -GroupKey "AdminDb.*" {
		
	}
}