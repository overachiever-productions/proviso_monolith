Set-StrictMode -Version 1.0;

Surface "DataCollectorSets" -Target "DataCollectorSets" {
	Assertions {
		Assert-UserIsAdministrator;
	}
	
	Aspect -IterateScope {
		
		Facet "Exists" -Key "Name" -ExpectKeyValue {
			Test {
				#TODO: this isn't the actual name (i..e, $PVContext.CurrentObjectName is the KEY ... not the name)
				$status = Get-PrmDataCollectorStatus -Name ($PVContext.CurrentObjectName);
				if ("<EMPTY>" -eq $status) {
					return "<EMPTY>";
				}
				
				return $PVContext.CurrentObjectName;
			}
			Configure {
				#TODO: this isn't the actual name (i..e, $PVContext.CurrentObjectName is the KEY ... not the name)
				$collectorSetName = $PVContext.CurrentObjectName;
				$expected = $PVContext.Expected;
				
				if ($expected) {
					
					# TODO: need to allow for 'overrides' of the xml config file - i.e., the code below just assumes/accepts that the DataCollectorSet def will be the <keyName>.xml
					# 		when... that's the CONVENTION, but there's a "DataCollectorSets.<collectorName>.XmlDefinition" key that CAN be used to overwrite/explicitly define a path... 
					#$xmlDefinition = $PVResources.GetAsset($collectorSetName, "xml", $false, $true);
					$xmlDefinition = $PVResources.GetDataCollectorSetDefinitionFile($collectorSetName);
					
					if (-not (Test-Path $xmlDefinition)) {
						throw "Data Collector Set Definition file for [$collectorSetName] - not found at path [$xmlDefinition].";
					}
					
					Copy-Item $xmlDefinition -Destination "C:\PerfLogs" -Force;
					
					$localDefinitionPath = Join-Path "C:\PerfLogs" -ChildPath (Split-Path -Path $xmlDefinition -Leaf);
					New-PrmDataCollectorFromFile -Name $collectorSetName -ConfigFilePath $localDefinitionPath;
				}
				else {
					$PVContext.WriteLog("Config setting for [DataCollectorSets.$collectorSetName.Enabled] is set to `$false - but a Data Collector Set with the name of [$collectorSetName] already exists. Proviso will NOT drop this Data Collector Set. Please make changes manually.", "Critical");
				}
			}
		}
		
		Facet "IsEnabled" -Key "Enabled" -ExpectKeyValue {
			Test {
				#TODO: this isn't the actual name (i..e, $PVContext.CurrentObjectName is the KEY ... not the name)
				$status = Get-PrmDataCollectorStatus -Name ($PVContext.CurrentObjectName);
				
				if ($status -like "<*") {
					return "<EMPTY>";  # emtpy... 
				}
				
				if ($status -eq "Running") {
					return $true;
				}
				
				if ($status -eq "Stopped") {
					return $false;
				}
			}
			Configure {
				#TODO: this isn't the actual name (i..e, $PVContext.CurrentObjectName is the KEY ... not the name)
				$collectorSetName = $PVContext.CurrentObjectName;
				$expected = $PVContext.Expected;
				
				# NOTE: if we're 'in here' it's because ACTUAL <> expected - so, set expected:
				if ($expected) {
					Start-PrmDataCollector -Name $collectorSetName;
				}
				else {
					Stop-PrmDataCollector -Name $collectorSetName;
				}
			}
		}
		
		Facet "EnableStartWithOS" -Key "EnableStartWithOS" -ExpectKeyValue {
			Test {
				# TODO: this isn't the name, it's the key... 
				$collectorSetName = $PVContext.CurrentObjectName;
				return Get-PrmDataCollectorAutoStart -Name $collectorSetName;				
			}
			Configure {
				$collectorSetName = $PVContext.CurrentObjectName;
				[bool]$expected = $PVContext.Expected;
				
				Enable-PrmDataCollectorAutoStart -Name $collectorSetName -Disable:(-not ($expected));
			}
		}
		
		Facet "RetentionDays" -Key "DaysWorthOfLogsToKeep" -ExpectKeyValue {
			Test {
				# TODO: this isn't the name, it's the key... 
				$collectorSetName = $PVContext.CurrentObjectName;
				return Get-PrmDataCollectorRetentionDays -Name $collectorSetName;
			}
			Configure {
				$collectorSetName = $PVContext.CurrentObjectName;
				$daysToRetain = $PVContext.Expected;
				
				# Ultimately, there will ALWAYS (effectively) be a cleanup - the default (i.e., if a value isn't specified) is 180 days...  
				$cleanupScript = $PVResources.GetAsset("Remove-OldCollectorSetFiles", "ps1");
				if (-not (Test-Path $cleanupScript)) {
					throw "PowerShell Script for Collector-Set File Cleanup NOT found at path [$cleanupScript]. Cannot continue with setup of cleanup tasks.";
				}
				
				Copy-Item $cleanupScript -Destination "C:\PerfLogs" -Force;
				Enable-PrmDataCollectorCleanup -Name $collectorSetName -RetentionDays $daysToRetain;
			}
		}
	}
}