Set-StrictMode -Version 1.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;
	With "\\storage\lab\proviso\definitions\servers\PRO\PRO-197.psd1"; 

	Configure-TestingSurface;
	Summarize -All; # -IncludeAllValidations; # -IncludeAssertions;

#>


Surface "TestingSurface" {
	
	Assertions  {
		Assert "IsTest" {
			return $True;  # just for testing (summary/output) purposes... 
		}
	}
	
	Rebase {
		# to test auto-generated props... 
	}
	
	Aspect {
		Facet "It is Tuesday" {
			Expect {
				return "Tuesday";
			}
			Test {
				
				if ($PVContext.GetSurfaceState("Tuesday.PostConfig")){
					return $PVContext.GetSurfaceState("Tuesday.PostConfig");
				}
				
				return [System.DateTime]::Now.DayOfWeek.ToString();
			}
			Configure {
				
				$faked = (Get-Date -Year 2021 -Month 12 -Day 28).DayOfWeek.ToString();
				$PVContext.SetSurfaceState("Tuesday.PostConfig", $faked);
			}
		}
		
		Facet "It is Saturday" {
			Expect {
				return "Saturday";
			}
			Test {
				if ($PVContext.GetSurfaceState("Saturday.PostConfig")) {
					return $PVContext.GetSurfaceState("Saturday.PostConfig");
				}
				return [System.DateTime]::Now.DayOfWeek.ToString();
			}
			Configure {
				
				$faked = (Get-Date -Year 2021 -Month 12 -Day 25).DayOfWeek.ToString();
				$PVContext.SetSurfaceState("Saturday.PostConfig", $faked);
			}
		}
		
		Facet "It is Friday" -Expect "Friday" {
			Test {
				return [System.DateTime]::Now.DayOfWeek.ToString();
			}
			Configure {
				# Don't do anything... 
			}
		}
		
		Facet "It is Sunday" -Expect "Sunday" -RequiresReboot {
			Test {
				return [System.DateTime]::Now.DayOfWeek.ToString();
			}
			Configure {
				# don't do anything... and see if ... <PENDING> pops up as result/outcome... 
			}
		}
		
		Facet "Deferred Facet" -Expect $true -UsesBuild {
			Test {
				# Test case here is that this'll effectively NEVER get called by itself - only by the 'child' or def below that DEFERS config to this facet.
				return $true;
			}
		}
		
		Facet "It is Deferred" -Expect "Deferred" -UsesBuild {
			Test {
				if ($PVContext.GetSurfaceState("Deferred.Deferred")) {
					return $PVContext.GetSurfaceState("Deferred.Deferred");
				}
				
				# otherwise, we'll get empty... 
			}
		}
		
		Build {
			$PVContext.SetSurfaceState("Deferred.Deferred", "Deferred");
		}
		
		Deploy {
			
		}
	}
}