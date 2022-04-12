Set-StrictMode -Version 1.0;

BeforeAll {
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "");
	
	. "$root\internal\dsl\ProvisoResources.ps1";
	#. "$root\internal\dsl\ProvisoConfig-Defaults.ps1";
	#$script:be8c742fDefaultConfigData = $script:ProvisoConfigDefaults;
}

Describe "PVResource Tests" {
	BeforeAll {
		New-Item -Path "TestDrive:\proviso" -ItemType "directory";
		
		# TODO: need to MOCK $PVContext... 
		
#		$PVResources.SetRoot("TestDrive:\proviso");
	}
	
	Context "GetAsset() Tests" {
		It "Allows Fully-Defined (hard-coded) Paths" {
				
		}
	}
}