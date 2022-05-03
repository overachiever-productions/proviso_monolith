Set-StrictMode -Version 1.0;

Surface SqlVersion -Target "SqlServerPatches" {
	
	Assertions {
		Assert-SqlServerIsInstalled -SurfaceTarget "SqlServerPatches" -AssertOnConfigureOnly;
	}
	
	Aspect {
		# Behaviour will be as follows: 
		# 		- for each facet, if there's a patch/CU specified, then extract version and display that as the expected version
		# 			AND... show the current/now version in play... 
		# 			OTHERWISE, if there's no SP/CU specified, set Expected to <N/A> and then Test will need to show <N/A> as well. 
		# 					(And there should be some easy way to do the above in terms of Test... )
		# 		- longer-term: if there is NOT an SP (sp only)... figure out some way to simply NOT include it in Summary. 
		# 				e.g., -NoSummaryFor "<N/A>" or something LIKE that... 
		# 		- longer-term2: if there's no CU... either show <N/A> or ... maybe set Expect AND Test to be {currentVersionRightNowOnServer}.
		
		#  ah... yes. the switch should be something pretty close to -SquelchSummaryIfExpectIs "<N/A>"
		Facet "Target SP" -Key "TargetSP" {
			Expect {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$sp = $PVConfig.GetValue("SqlServerPatches.$instanceName.TargetSP");
				
				try {
					if ($sp) {
						$filePath = $PVResources.GetSqlSpOrCu($sp);
						if ($filePath) {
							return (Get-ItemProperty -Path $filePath).VersionInfo.ProductVersion;
						}
					}
				}
				catch {
					throw "Fatal Exception Evaluating Target Version from File Properties for SP [$sp].";
				}
				
				return "<N/A>";
			}
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				$sp = $PVConfig.GetValue("SqlServerPatches.$instanceName.TargetSP");
				
				if ($sp) {
					return Get-SqlServerInstanceCurrentVersion -InstanceName $instanceName;
				}
				
				return "<N/A>";
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$sp = $PVConfig.GetValue("SqlServerPatches.$instanceName.TargetSP");
				
				if ($PVContext.RebootRequired) {
					$PVContext.WriteLog("Could NOT install SP [$sp] - because a Server Reboot is PENDING.", "Critical");
				}
				else {
					$filePath = $PVResources.GetSqlSpOrCu($sp);
					Install-SqlServerPatch -InstanceName $instanceName -SpOrCuPath $filePath;
					
					$PVContext.SetRebootRequired("Reboot Required after installation of SQL Server Service Pack.");
				}
			}
		}
		Facet "Target CU" -Key "TargetCU" {
			Expect {
				$instanceName = $PVContext.CurrentSqlInstance;
				
				$targetVersion = $null;
				$cu = $PVConfig.GetValue("SqlServerPatches.$instanceName.TargetCU");
				
				try {
					if ($cu) {
						$filePath = $PVResources.GetSqlSpOrCu($cu);
						if ($filePath) {
							return (Get-ItemProperty -Path $filePath).VersionInfo.ProductVersion;
						}
					}
				}
				catch {
					throw "Fatal Exception Evaluating Target Version from File Properties for CU [$cu].";
				}
				
				return "<N/A>";
			}
			Test {
				$instanceName = $PVContext.CurrentSqlInstance;
				$cu = $PVConfig.GetValue("SqlServerPatches.$instanceName.TargetCU");
				
				if ($cu) {
					return Get-SqlServerInstanceCurrentVersion -InstanceName $instanceName;
				}
				
				return "<N/A>";
			}
			Configure {
				$instanceName = $PVContext.CurrentSqlInstance;
				$cu = $PVConfig.GetValue("SqlServerPatches.$instanceName.TargetCU");
				
				if ($PVContext.RebootRequired) {
					$PVContext.WriteLog("Could NOT install CU [$cu] - because a Server Reboot is PENDING.", "Critical");
				}
				else
				{
					$filePath = $PVResources.GetSqlSpOrCu($cu);
					Install-SqlServerPatch -InstanceName $instanceName -SpOrCuPath $filePath;
					
					$PVContext.SetRebootRequired("Reboot Required after installation of SQL Server Cummulative Update.");
				}
			}
		}
		
#		Facet "Target Version" {
#			Expect {
#				$instanceName = $PVContext.CurrentSqlInstance;
#				
#				$targetVersion = $null;
#				$sp = $PVConfig.GetValue("SqlServerPatches.$instanceName.TargetSP");
#				$cu = $PVConfig.GetValue("SqlServerPatches.$instanceName.TargetCU");
#				
#				try {
#					if ($cu) {
#						$filePath = $PVResources.GetSqlSpOrCu($cu);
#						if ($filePath) {
#							$targetVersion = (Get-ItemProperty -Path $filePath).VersionInfo.ProductVersion;
#						}
#					}
#					elseif ($sp) {
#						$filePath = $PVResources.GetSqlSpOrCu();
#						if ($filePath) {
#							$targetVersion = (Get-ItemProperty -Path $filePath).VersionInfo.ProductVersion;
#						}
#					}
#					
#					if ($null -eq $targetVersion) {
#						$targetVersion = Get-SqlServerInstanceCurrentVersion -InstanceName $instanceName;
#					}
#				}
#				catch {
#					
#				}
#				
#				return $targetVersion;
#			}
#			Test {
#				$instanceName = $PVContext.CurrentSqlInstance;
#				
#				Get-SqlServerInstanceCurrentVersion -InstanceName $instanceName;
#			}
#			Configure {
#				$instanceName = $PVContext.CurrentSqlInstance;
#				
#				$sp = $PVConfig.GetValue("SqlServerPatches.$instanceName.TargetSP");
#				$cu = $PVConfig.GetValue("SqlServerPatches.$instanceName.TargetCU");
#				
#				# TODO: if the current RUNBOOK allows reboots, then ... just reboot here ... 
#				#  		i.e., reboot IF we're pending a reboot prior to both/either SP or CU installs... period.
#				
#				# TODO: ugh... 
#				#  	so. let's say that: 
#				# 		> it's a fresh box/install, and there are no reboots pending. 
#				# 		> BUT, we have BOTH an SP _AND_ a CU. 
#				# 		> the SP deploys without issues and 
#				# 		> we kick off a reboot - telling Proviso to come BACK to this surface when reboot is done. 
#				# 		> SIGH: at that point, we'll restart with an attempted installation of ... the SP... 
#				
#				# 		as in, there needs to be a part of the CONFIGURE process that determines what the current VERSION is 'right this second'
#				# 		and, if we've already 'met' that by means of an SP, then don't install the SP and, likewise, same for the CU (though, technicall
#				# 				we should NEVER be at a point where a CU should have to play by this rule/logic - i.e., should ONLY be if/when there are
#				# 				2x of these things. )
#				# 		ARGUABLY, it MIGHT make more sense to look at having a DISTINCT facet for an SP and ONLY display it if there's an SP present. 
#				# 		AND to have a SEPARATE facet for a CU and only display that IF it's present. 
#				# 			AND... both COULD, of course, be present, but ... there/could should be some sort of (again) OPTION to skip if such and such
#				# 			during the 'expectation' phase/processing is empty or whatever... 
#				# 		that'd make this all a LOT better.
#				if ($sp) {
#					if ($PVContext.RebootRequired) {
#						$PVContext.WriteLog("Could NOT install SP [$sp] - because a Server Reboot is PENDING.", "Critical");
#					}
#					else {
#						Install-SqlServerPatch -InstanceName $instanceName -SpOrCuPath $sp;
#						
#						$PVContext.SetRebootRequired("Reboot Required after installation of SQL Server Service Pack.");
#					}
#				}
#				
#				if ($cu) {
#					if ($PVContext.RebootRequired) {
#						$PVContext.WriteLog("Could NOT install CU [$cu] - because a Server Reboot is PENDING.", "Critical");
#					}
#					{
#						Install-SqlServerPatch -InstanceName $instanceName -SpOrCuPath $cu;
#						
#						$PVContext.SetRebootRequired("Reboot Required after installation of SQL Server Cummulative Update.");
#					}
#				}
#			}
#		}
	}
}