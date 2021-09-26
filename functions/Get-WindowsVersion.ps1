Set-StrictMode -Version 1.0;

<#
		# https://en.wikipedia.org/wiki/List_of_Microsoft_Windows_versions#Server_versions
		# https://www.techthoughts.info/windows-version-numbers/

#>

# for callers (that consume this info):  [ValidateSet("Windows2012R2", "Windows2016", "Windows2019")]

function Get-WindowsVersion {
	
	param (
		[System.Version]$Version = [System.Environment]::OSVersion.Version
	)
	
	if ($Version.Major -eq 10) {
		if ($Version.Build -ge 17763) {
			return "Windows2019";
		}
		else {
			return "Windows2016";
		}
		
		#$output = $Version.Build -ge 17763 ? "Windows2019" : "Windows2016";
	}
	
	if ($Version.Major -eq 6){
		switch ($Version.Minor) {
			0 {
				return "Windows2008";
			}
			1 {
				return "Windows2008R2";
			}
			2 {
				return "Windows2012";
			}
			3 {
				return "Windows2012R2";
			}
			default {
				return "UNKNOWN"
			}
		}
	}
}