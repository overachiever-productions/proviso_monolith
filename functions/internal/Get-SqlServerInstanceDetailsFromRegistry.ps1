Set-StrictMode -Version 1.0;

function Get-SqlServerInstanceDetailsFromRegistry {
	
	param (
		[Parameter(Mandatory)]
		[string]$InstanceName,
		[Parameter(Mandatory)] # todo.. limit to just the values defined below... 
		[string]$Detail
	);
	
	begin {
		$instanceKey = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\').$InstanceName;
		if ($null -eq $instanceKey) {
			throw "SQL Server Instance [$InstanceName] not found in registry or not installed.";
		}
	};
	
	process {
		
		switch ($Detail) {
			"Collation" {
				return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\Setup").Collation;
			}
			"DefaultBackups" {
				return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\$InstanceName").BackupDirectory;
			}
			"DefaultData" {
				return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\$InstanceName").DefaultData;
			}
			"DefaultLog" {
				return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\$InstanceName").DefaultLog;
			}
			"Edition" {
				$edition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\Setup").Edition;
				return ($edition -replace " Edition", "");
			}
			"Features" {
				throw "Need to figure out how to parse (`"HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\Setup`").FeatureList"
			}
			"MixedMode" {
				$value = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\$InstanceName").LoginMode;
				if (2 -eq $value) {
					return $true;
				}
				return $false;
			}
			"VersionName" {
				$version = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\Setup").Version;
				[string[]]$parts = $version -split '\.';
				
				switch ($parts[0]) {
					15 {
						return "2019";
					}
					14 {
						return "2017";
					}
					13 {
						return "2016";
					}
					12 {
						return "2014"
					}
					11 {
						return "2012"
					}
					10 {
						if ($parts[1] -eq 0) {
							return "2008";
						}
						
						return "2008 R2";
					}
					9 {
						return "2005";
					}
					8 {
						return "2000";
					}
					7 {
						return "SQL Server 7.0";
					}
				}
			}
			"VersionNumber" {
				return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\Setup").Version;
			}
		}
	};
	
	end {
		
	};
}