Set-StrictMode -Version 1.0;

Surface "TestingSurface" {
	
	Assertions  {
		Assert "IsTest" {
			return $True;  # just for testing (summary/output) purposes... 
		}
	}
	
	Definitions {
		Definition "It is Tuesday" {
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
				$PVContext.AddSurfaceState("Tuesday.PostConfig", $faked);
			}
		}

		Definition "It is Saturday" {
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
				$PVContext.AddSurfaceState("Saturday.PostConfig", $faked);
			}
		}
		
		Definition "It is Friday" -Expect "Friday" {
			Test {
				return [System.DateTime]::Now.DayOfWeek.ToString();
			}
			Configure {
				# Don't do anything... 
			}
		}
		
		Definition "It is Sunday" -Expect "Sunday" -RequiresReboot {
			Test {
				return [System.DateTime]::Now.DayOfWeek.ToString();
			}
			Configure {
				# don't do anything... and see if ... <PENDING> pops up as result/outcome... 
			}
		}
		
		Definition "Deferred Definition" -Expect $true {
			Test {
				# Test case here is that this'll effectively NEVER get called by itself - only by the 'child' or def below that DEFERS config to this definition.
				return $true;
			}
			Configure {
				$PVContext.AddSurfaceState("Deferred.Deferred", "Deferred");
			}
		}
		
		Definition "It is Deferred" -Expect "Deferred" -ConfiguredBy "Deferred Definition" {
			Test {
				if ($PVContext.GetSurfaceState("Deferred.Deferred")) {
					return $PVContext.GetSurfaceState("Deferred.Deferred");
				}
				
				# otherwise, we'll get empty... 
			}
		}
	}
}