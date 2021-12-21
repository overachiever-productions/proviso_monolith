Set-StrictMode -Version 1.0;

Facet "DataCollectorSets" {
	Assertions {
		
	}
	
<# 

	Assume the following is what the config looks like: 
	DataCollectorSets  = @{
		
		Consolidated = @{
			Enabled			      = $true
			XmlDefinition		  = ""
			EnableStartWithOS	  = $true
			DaysWorthOfLogsToKeep = "45" # if empty then ... keep them all (no cleanup)
		}
		
		AnotherDataSetNameHere = @{
			Enabled = $false;
			# other values, technicall, don't matter... 
		}
	}
	
	
#>
	
	Group-Definitions -GroupKey "DataCollectorSets.*" {
		Definition "IsEnabled" -ExpectChildKey "Enabled" {
			Test {
				# is xxx enabled? 
				$value = $PVContext.CurrentKeyValue;
				$group = $PVContext.CurrentKeyGroup;
				
				#Write-Host "This would be a test for Group: $group with a value of $value ";
				
				# simulated results: 
				if ($group -eq "Consolidated") {
					return $false;
				}
				
				return $false;
			}
			Configure {
				# do whatever it takes to turn xxx on... 
				$value = $PVContext.CurrentKeyValue;
				$group = $PVContext.CurrentKeyGroup;
				
				#Write-Host "Do whatever is needed to set the Enabled Status of DataCollectorSet: [$group] to [$value];";
				$configDataForXmlDef = $PVConfig.GetValue("DataCollectorSets.$group.XmlDefinition");
				
				#Write-Host "If needed, the value for XML def would be: $configDataForXmlDef ";
				
			}
		}
	}
}