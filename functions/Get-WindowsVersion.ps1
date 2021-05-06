Set-StrictMode -Version 1.0;

function Get-WindowsVersion {
	$version = [System.Environment]::OSVersion.Version;
	
	# https://en.wikipedia.org/wiki/List_of_Microsoft_Windows_versions#Server_versions
	if ($version.Major -eq 10) {
		# could be 2019 or 2016...
		# https://www.techthoughts.info/windows-version-numbers/
	}
	
	if ($version.Major -eq 6){
		# 6.3 = 2012R2, #6.2 = 2012
	}
	
}