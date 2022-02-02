Set-StrictMode -Version 1.0;

Surface "DataCollectorSets" {
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
	
	Aspect -Scope "DataCollectorSets.*" {
		Facet "IsEnabled" -ExpectChildKeyValue "Enabled" {
			Test {
				
				#	Write-Host "Collectors:Current Key: $($PVContext.CurrentKey)"
				#	Write-Host "Collectors:Current Key VALUE: $($PVContext.CurrentKeyValue)"
				#	Write-Host "Collectors:Current _CHILD_ Key: $($PVContext.CurrentChildKey)"
				#	Write-Host "Collectors:Current _CHILD_ Key VALUE: $($PVContext.CurrentChildKeyValue)"
				
				# is xxx enabled? 
				
				# simulated results: 
			#				if ($group -eq "Consolidated") {
			#					return $false;
			#				}
			#				
			#				return $false;
			}
			Configure {
				# do whatever it takes to turn xxx on... 

				#Write-Host "Do whatever is needed to set the Enabled Status of DataCollectorSet: [$group] to [$value];";
				$configDataForXmlDef = $PVConfig.GetValue("DataCollectorSets.$group.XmlDefinition");
				
				#Write-Host "If needed, the value for XML def would be: $configDataForXmlDef ";
				
			}
		}
	}
}