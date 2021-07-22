Set-StrictMode -Version 1.0;

<#
		# https://en.wikipedia.org/wiki/List_of_Microsoft_Windows_versions#Server_versions
		# https://www.techthoughts.info/windows-version-numbers/

#>

# [ValidateSet("Windows2012R2", "Windows2016", "Windows2019")]

function Get-WindowsVersion {
	
	param (
		[System.Version]$Version = [System.Environment]::OSVersion.Version
	)
	
	[string]$output;
	
	
	if ($Version.Major -eq 10) {
		if ($Version.Build -ge 17763) {
			$output = "Windows2019";
		}
		else {
			$output = "Windows2016";
		}
		
		#$output = $Version.Build -ge 17763 ? "Windows2019" : "Windows2016";
	}
	
	if ($Version.Major -eq 6){
		switch ($Version.Minor) {
			0 {
				$output = "Windows2008";
			}
			1 {
				$output = "Windows2008R2";
			}
			2 {
				$output = "Windows2012";
			}
			3 {
				$output = "Windows2012R2";
			}
			default {
				$output = "UNKNOWN"
			}
		}
	}
	
	return $output;
}