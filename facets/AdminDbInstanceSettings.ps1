Set-StrictMode -Version 1.0;

Facet AdminDbInstanceSettings {
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	Group-Definitions -GroupKey "AdminDb.*" {
		Definition "MAXDOP" -ExpectValueForChildKey "ConfigureInstance.MAXDOP" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$maxdop = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT value_in_use [current] FROM sys.[configurations] WHERE [name] = N'max degree of parallelism'; ").current;
				
				return $maxdop;
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				# TODO: Invoke-SQLCmd's Parameter implementation is _USELESS_. 
				#   see https://overachieverllc.atlassian.net/browse/PRO-187 and https://overachieverllc.atlassian.net/browse/PRO-188
				$params = "P1=$expectedSetting";
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "EXEC admindb.dbo.[configure_instance] @MaxDOP = `$(P1); " -Variable $params;
			}
		}
		
		Definition "MaxServerMemory" {
			Expect {
				$instanceName = $PVContext.CurrentKeyValue;
				$nonDefaultValue = $PVConfig.GetValue("AdminDb.$instanceName.ConfigureInstance.MaxServerMemoryGBs");
				if ($nonDefaultValue) {
					return $nonDefaultValue;
				}
				
				return "<UNLIMITED>";
			}
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$maxMem = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT CAST(CAST(value_in_use AS int) / 1024.0 AS decimal(8,1)) [current] FROM sys.[configurations] WHERE [name] = N'max server memory (MB)'; ").current;
				if ($maxMem -eq 2097152.0) {
					return "<UNLIMITED>";
				}
				
				return $maxMem;
				
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				
				# Pull from config
				$expectedSetting = 2097152.0; # unlimited... 
				$nonDefaultValue = $PVConfig.GetValue("AdminDb.$instanceName.ConfigureInstance.MaxServerMemoryGBs");
				if ($nonDefaultValue) {
					$expectedSetting = $nonDefaultValue;
				}
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "EXEC admindb.dbo.[configure_instance] @MaxServerMemoryGBs = $expectedSetting; ";
			}
		}
		
		Definition "CTFP" -ExpectValueForChildKey "ConfigureInstance.CostThresholdForParallelism" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$ctfp = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT value_in_use [current] FROM sys.[configurations] WHERE [name] = N'cost threshold for parallelism'; ").current;
				
				return $ctfp;
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "EXEC admindb.dbo.[configure_instance] @CostThresholdForParallelism = $expectedSetting; ";
			}
		}
		
		Definition "OptimizeForAdHoc" -ExpectValueForChildKey "ConfigureInstance.OptimizeForAdHocQueries" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$optimizeForAdhoc = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT value_in_use [current] FROM sys.[configurations] WHERE [name] = N'optimize for ad hoc workloads'; ").current;
				
				if ($optimizeForAdhoc -eq 1) {
					return $true;
				}
				
				return $false;
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$setting = 0;
				if ($expectedSetting) {
					$setting = 1;
				}
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "EXEC admindb.dbo.[configure_instance] @OptimizeForAdhocWorkloads = $setting; ";
			}
		}
		
	}
}