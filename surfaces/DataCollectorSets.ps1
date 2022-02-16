﻿Set-StrictMode -Version 1.0;


<# 

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	Assign -ProvisoRoot "\\storage\Lab\proviso\";
	Target "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1";

	Validate-DataCollectorSets;
	Summarize -Latest;

#>


Surface "DataCollectorSets" {
	Assertions {
		
	}
	
	Aspect -Scope "DataCollectorSets.*" {
		Facet "IsEnabled" -ExpectCurrentKeyValue {
			Test {
				$collectorSetName = $PVContext.CurrentKeyValue;
				
				$status = Get-DataCollectorSetStatus -Name $collectorSetName;
				if ($status -like "<*") {
					return $status;
				}
				
				if ($status -eq "Running") {
					#return $true;
					return $collectorSetName;
				}
				
				if ($status -eq "Stopped") {
					return "<STOPPED>";
				}
			}
			Configure {
				$collectorSetName = $PVContext.CurrentKeyValue;
				$expected = $PVContext.Expected;
				
				if ($expected) {
					
					# TODO: need to allow for 'overrides' of the xml config file - i.e., the code below just assumes/accepts that the DataCollectorSet def will be the <keyName>.xml
					# 		when... that's the CONVENTION, but there's a "DataCollectorSets.<collectorName>.XmlDefinition" key that CAN be used to overwrite/explicitly define a path... 
					
					$xmlDefinition = $PVResources.GetAsset($collectorSetName, "xml", $false, $true);
					if (-not (Test-Path $xmlDefinition)) {
						throw "Data Collector Set Definition file for [$collectorSetName] - not found at path [$xmlDefinition].";
					}
					
					Copy-Item $xmlDefinition -Destination "C:\PerfLogs" -Force; # note that we DO copy the definition LOCAL, but the SOURCE is the remote/foreign file... 
					New-DataCollectorSetFromConfigFile -Name $collectorSetName -ConfigFilePath $xmlDefinition; 
				}
				else {
					$PVContext.WriteLog("Config setting for [DataCollectorSets.$collectorSetName.Enabled] is set to `$false - but a Data Collector Set with the name of [$collectorSetName] already exists. Proviso will NOT drop this Data Collector Set. Please make changes manually.", "Critical");
				}
			}
		}
		
		Facet "EnableStartWithOS" -ExpectChildKeyValue "EnableStartWithOS" {
			Test {
				$collectorSetName = $PVContext.CurrentKeyValue;
				
				# Since TaskScheduler tasks SUCK so much AND since Posh sucks in terms of support, it's EASIER to simple extract the XML for tasks and 'go that route'... 
				$path = "C:\Windows\System32\Tasks\Microsoft\Windows\PLA\$collectorSetName";
				if (-not (Test-Path $path)) {
					return $false;
				}
				
				$xmlTask = New-Object System.Xml.XmlDocument;
				$xmlTask.Load($path);
				$bootTrigger = ($xmlTask).Task.Triggers.BootTrigger.Enabled; 
				
				[bool]$startWithOs = $bootTrigger;
				if ($startWithOs) {
					$command = ($xmlTask).Task.Actions.Exec.Command;
					$arguments = ($xmlTask).Task.Actions.Exec.Arguments;
					
					if (($command -eq "C:\windows\system32\rundll32.exe") -and ($arguments -eq 'C:\windows\system32\pla.dll,PlaHost "Consolidated" "$(Arg0)"')) {
						return $true;
					}
				}
				
				return $false;
			}
			Configure {
				$collectorSetName = $PVContext.CurrentKeyValue;
				[bool]$expected = $PVContext.Expected;
				
				Enable-DataCollectorSetForAutoStart -Name $collectorSetName -Disable:(-not ($expected));
			}
		}
		
		Facet "RetentionDays" -ExpectChildKeyValue "DaysWorthOfLogsToKeep" {
			Test {
				$collectorSetName = $PVContext.CurrentKeyValue;
								
				# Ditto on scheduled tasks sucking - i.e., using xml instead: 
				$path = "C:\Windows\System32\Tasks\$collectorSetName - Cleanup Older Files";
				if (-not (Test-Path $path)) {
					return $false;
				}
				
				$xmlTask = New-Object System.Xml.XmlDocument;
				$xmlTask.Load($path);
				
				$arguments = ($xmlTask).Task.Actions.Exec.Arguments;
				if ($arguments) {
					
					$regex = New-Object System.Text.RegularExpressions.Regex('-RetentionDays (?<days>[0-9]+)', [System.Text.RegularExpressions.RegexOptions]::Singleline);
					$matches = $regex.Match($arguments);
					if ($matches) {
						$days = $matches.Groups[1].Value;
						
						return $days;
					}
				}
			}
			Configure {
				$collectorSetName = $PVContext.CurrentKeyValue;
				$daysToRetain = $PVContext.Expected;
				
				# Ultimately, there will ALWAYS (effectively) be a cleanup - the default (i.e., if a value isn't specified) is 180 days...  
				$cleanupScript = $PVResources.GetAsset("Remove-OldCollectorSetFiles", "ps1");
				if (-not (Test-Path $cleanupScript)) {
					throw "PowerShell Script for Collector-Set File Cleanup NOT found at path [$cleanupScript]. Cannot continue with setup of cleanup tasks.";
				}
				
				Copy-Item $cleanupScript -Destination "C:\PerfLogs" -Force;
				New-DataCollectorSetFileCleanupJob -Name $collectorSetName -RetentionDays $daysToRetain;
			}
		}
	}
}