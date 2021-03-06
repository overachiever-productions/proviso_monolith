
$root = Split-Path -Parent $MyInvocation.MyCommand.Path.Replace("\tests", "\functions");
$sut = Split-Path -Leaf $MyInvocation.MyCommand.Path.Replace(".Tests.", ".");
$functionName = $sut.Replace(".ps1", "");


Describe "Scaffolding Test" {
	
	It "Correctly Derives File Name" {
		$functionName | Should -Be "Setup";
	}
	
}