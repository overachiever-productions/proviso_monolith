﻿Set-StrictMode -Version 1.0;

Surface AdminDb -Target "AdminDb" {
	
	Assertions {
		Assert-SqlServerIsInstalled -SurfaceTarget "AdminDb" -ConfigureOnly;
	}
	
	Aspect {
		Facet "Deployed" -Key "Deploy" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$exists = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [name] FROM sys.databases WHERE [name] = 'admindb'; ").name;
				if ($exists) {
					return $true;
				}
				
				return $false;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$expectedSetting = $PVContext.CurrentConfigKeyValue;
				
				if ($expectedSetting) {
					$adminDbOverridePath = $PVConfig.GetValue("AdminDb.$instanceName.OverrideSource");
					
					$latestAdminDbSqlFile = $PVResources.GetAdminDbPath($instanceName, $adminDbOverridePath);
					
					Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -InputFile $latestAdminDbSqlFile -DisableVariables | Out-Null;
					Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "EXEC [admindb].dbo.[enable_advanced_capabilities]; " | Out-Null;
					
					$PVContext.SetSurfaceState("$instanceName.AdminDb.JustInstalled", $true);
					$PVContext.WriteLog("AdminDb installed (not found previously).", "Verbose");
				}
				else {
					$PVContext.WriteLog("Config setting for [AdminDb.$instanceName.Deploy] is set to `$false - the admindb has already been debployed. Proviso will NOT remove this database automatically. Please remove manually.", "Critical");
				}
			}
		}
		
		Facet "AdminDbVersion" -NoKey {
			Expect {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				# check for hard-override path first, then from URI, then ... as asset: 
				$adminDbOverridePath = $PVConfig.GetValue("AdminDb.$instanceName.OverrideSource");
				if ($adminDbOverridePath) {
					if (Test-Path $adminDbOverridePath) {
						$content = Get-Content -Path $adminDbOverridePath;
						$regex = New-Object System.Text.RegularExpressions.Regex('S4 version (?<version>[0-9.]{5,12}) or', [System.Text.RegularExpressions.RegexOptions]::Multiline);
						$matches = $regex.Match($content);
						if ($matches) {
							$version = $matches.Groups[1].Value;
							if ($version) {
								return $version;
							}
						}
					}
				}
				
				$release = Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/overachiever-productions/S4/releases/latest" -TimeoutSec 8 -ErrorAction SilentlyContinue;
				if ($release) {
					return $release.tag_name;
				}
				
				# if we're still here:
				$assetPath = $PVResources.GetAsset("admindb_latest", "sql");
				if ($assetPath) {
					if (Test-Path $assetPath) {
						$content = Get-Content -Path $assetPath;
						$regex = New-Object System.Text.RegularExpressions.Regex('S4 version (?<version>[0-9.]{5,12}) or', [System.Text.RegularExpressions.RegexOptions]::Multiline);
						$matches = $regex.Match($content);
						if ($matches) {
							$version = $matches.Groups[1].Value;
							if ($version) {
								return $version;
							}
						}
					}
				}
			}
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$exists = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [name] FROM sys.databases WHERE [name] = 'admindb'; ").name;
				if ($exists) {
					$version = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT version_number [version] FROM [admindb].dbo.[version_history] WHERE [version_id] = (SELECT MAX(version_id) FROM [admindb].dbo.[version_history]); ").version;
					
					return $version;
				}
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				# if we're here... it's ONLY because expected version and actual didn't match. So, try to re-install... 
				#  	that SHOULD fix it unless there's a hard-coded copy of an older version somewhere... but that's a config issue not a framework problem.
				# and... don't install if we JUST installed: 
				if (-not ($PVContext.GetSurfaceState("$instanceName.AdminDb.JustInstalled"))) {
					$PVContext.WriteLog("Installing AdminDb because expected version and actual version did not match.", "Verbose");
					$adminDbOverridePath = $PVConfig.GetValue("AdminDb.$instanceName.OverrideSource");
					$latestAdminDbSqlFile = $PVResources.GetAdminDbPath($instanceName, $adminDbOverridePath);
					
					Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -InputFile $latestAdminDbSqlFile -DisableVariables;
				}
				
			}
		}
	}
}