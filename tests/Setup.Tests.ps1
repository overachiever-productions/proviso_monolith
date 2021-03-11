BeforeAll {
	$root = Split-Path -Parent $PSCommandPath.Replace("\tests", "\functions");
	$sut = Split-Path -Leaf $PSCommandPath.Replace(".Tests.", ".");
	$functionName = $sut.Replace(".ps1", "");
}

Describe "Scaffolding Test" {
	
	It "Correctly compares Static Content" {
		"Static" | Should -Be "Static";
	}
	
	It "Correctly Derives File Name" {
		$functionName | Should -Be "Setup";
	}
	
}