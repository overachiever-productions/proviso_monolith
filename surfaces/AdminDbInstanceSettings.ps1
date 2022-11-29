Set-StrictMode -Version 1.0;

Surface AdminDbInstanceSettings -Target "AdminDb" {
	Assertions {
		Assert-SqlServerIsInstalled -ConfigureOnly;
		Assert-AdminDbInstalled -ConfigureOnly;
	}
	
	Aspect -Scope "InstanceSettings" {
		Facet "MAXDOP" -Key "MAXDOP" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$maxdop = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT value_in_use [current] FROM sys.[configurations] WHERE [name] = N'max degree of parallelism'; ").current;
				
				return $maxdop;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$expectedSetting = $PVContext.CurrentConfigKeyValue;
				
				# TODO: Invoke-SQLCmd's Parameter implementation is _USELESS_. 
				#   see https://overachieverllc.atlassian.net/browse/PRO-187 and https://overachieverllc.atlassian.net/browse/PRO-188
				$params = "P1=$expectedSetting";
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "EXEC admindb.dbo.[configure_instance] @MaxDOP = `$(P1); " -Variable $params;
			}
		}
		
		Facet "MaxServerMemory" -Key "MaxServerMemoryGBs" {
			Expect {
				$instanceName = $PVContext.CurrentSqlInstance;
				$nonDefaultValue = $PVConfig.CurrentConfigKeyValue;
				if ($nonDefaultValue) {
					return $nonDefaultValue;
				}
				
				return "<UNLIMITED>";
			}
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$maxMem = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT CAST(CAST(value_in_use AS int) / 1024.0 AS decimal(8,1)) [current] FROM sys.[configurations] WHERE [name] = N'max server memory (MB)'; ").current;
				if ($maxMem -eq 2097152.0) {
					return "<UNLIMITED>";
				}
				
				return $maxMem;
				
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				# Pull from config
				$expectedSetting = 2097152.0; # unlimited... 
				$nonDefaultValue = $PVConfig.GetValue("AdminDb.$instanceName.ConfigureInstance.MaxServerMemoryGBs");
				if ($nonDefaultValue) {
					$expectedSetting = $nonDefaultValue;
				}
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "EXEC admindb.dbo.[configure_instance] @MaxServerMemoryGBs = $expectedSetting; ";
			}
		}
		
		Facet "CTFP" -Key "CostThresholdForParallelism" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$ctfp = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT value_in_use [current] FROM sys.[configurations] WHERE [name] = N'cost threshold for parallelism'; ").current;
				
				return $ctfp;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$expectedSetting = $PVContext.CurrentConfigKeyValue;
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "EXEC admindb.dbo.[configure_instance] @CostThresholdForParallelism = $expectedSetting; ";
			}
		}
		
		Facet "OptimizeForAdHoc" -Key "OptimizeForAdHocQueries" -ExpectKeyValue {
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				if ($instanceName -notin (Get-ExistingSqlServerInstanceNames)) {
					return "";
				}
				
				$optimizeForAdhoc = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT value_in_use [current] FROM sys.[configurations] WHERE [name] = N'optimize for ad hoc workloads'; ").current;
				
				if ($optimizeForAdhoc -eq 1) {
					return $true;
				}
				
				return $false;
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$expectedSetting = $PVContext.CurrentConfigKeyValue;
				
				$setting = 0;
				if ($expectedSetting) {
					$setting = 1;
				}
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "EXEC admindb.dbo.[configure_instance] @OptimizeForAdhocWorkloads = $setting; ";
			}
		}
	}
}