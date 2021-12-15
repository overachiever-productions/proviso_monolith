Set-StrictMode -Version 1.0;

Facet "TestingFacet" {
	
	Assertions  {
		Assert -Has "Domain Admin Creds" -NonFatal {
			return $false;
		}
		
		Assert "Something Impossible" -FailureMessage "Dare to Dream?" {
			return $false;
		}
		
		Assert "Fake Test" -NotFatal -Ignored {
			throw "Test Exception."; # simple test of non-fatal assertions... 
		}
		
		Assert "Thrown Around" {
			throw "ouch!";
		}
	}
	
	Definitions {
		Definition "It is Tuesday" {
			Expect {
				return "Tuesday";
			}
			Test {
				return [System.DateTime]::Now.DayOfWeek.ToString();
			}
			Configure {
				# Don't do anything.
				# It's either tuesday, or it's not - in which case, there won't be an error/exception
				#  during 'config',  but the 'configuration' won't actually work and will be reported as such.
				#return $true;
			}
		}
	}
	
	Definitions {
		Definition "It is Saturday" {
			Expect {
				return "Saturday";
			}
			Test {
				return [System.DateTime]::Now.DayOfWeek.ToString();
			}
			Configure {
				# Don't do anything.
				# It's either tuesday, or it's not - in which case, there won't be an error/exception
				#  during 'config',  but the 'configuration' won't actually work and will be reported as such.
				#return $true;
			}
		}
	}
}