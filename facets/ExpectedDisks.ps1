Set-StrictMode -Version 1.0;
#
#Facet "ExpectedDisks" {
#	Assertions {
#		
#	}
#	
#	Group-Definitions -GroupKey "Host.ExpectedDisks.*"	{
#		Definition "Physical Disk Exists" -Expect $true {
#			Test {
#				
#			}
#			Configure {
#				#grab an avail
#			}
#		}
#		
#		Definition "Logical Disk Exists" -Expect $true {
#			Test {
#				
#			}
#			Configure {
#				
#			}
#		}
#		
#		Definition "Logical Disk Formatted" -Expect $true {
#			Test {
#				
#			}
#			Configure {
#				# hmmm... yeah, might need to ditch this one... 
#			}
#		}
#		
#		Definition "Logical Disk Using LargeFRS" -Expect $true {
#			Test {
#				
#			}
#			Configure {
#				# yeah... no. don't DO anything.
#			}
#		}
#		
#	}
#}