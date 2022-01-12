Set-StrictMode -Version 1.0;

Facet "TestingFacet" {
	
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
				
				if ($PVContext.GetFacetState("Tuesday.PostConfig")){
					return $PVContext.GetFacetState("Tuesday.PostConfig");
				}
				
				return [System.DateTime]::Now.DayOfWeek.ToString();
			}
			Configure {
				
				$faked = (Get-Date -Year 2021 -Month 12 -Day 28).DayOfWeek.ToString();
				$PVContext.AddFacetState("Tuesday.PostConfig", $faked);
			}
		}

		Definition "It is Saturday" {
			Expect {
				return "Saturday";
			}
			Test {
				if ($PVContext.GetFacetState("Saturday.PostConfig")) {
					return $PVContext.GetFacetState("Saturday.PostConfig");
				}
				return [System.DateTime]::Now.DayOfWeek.ToString();
			}
			Configure {
				
				$faked = (Get-Date -Year 2021 -Month 12 -Day 25).DayOfWeek.ToString();
				$PVContext.AddFacetState("Saturday.PostConfig", $faked);
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
	}
}