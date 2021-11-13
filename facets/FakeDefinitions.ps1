#Set-StrictMode -Version 1.0;
#
#Facet "FakeDefinitions" -For "Testing Puproses only" {
#	
#	
#	Definitions {
#		Definition "This one should throw" -Key "Host.AllowGlobalDefaults" {
#			Test {
#				return $false;
#			}
#
#		}
#
#		Definition "Host-Name Test" -For -Key "Host.TargetServer" {
#			Test {
#				return $false;
#			}
#			Configure {
#				Write-Host "fake operation";
#			}
#		}
#		
#		Definition "Simple Array test" -For -Key "SqlServerConfiguration.MSSQLSERVER.TraceFlags" {
#			Test {
#				return $false;
#			}
#			Configure {
#				Write-Host "fake operation";
#			}
#		}
#
#
#		Definition "Bogus Firewall Rule" -For -Key "Host.FirewallRules.EnableHTTPs" {
#			Test {
#				return $false;
#			}
#			Configure {
#				Write-Host "fake operation";
#			}
#		}
#
#		Definition "Shares - Array Test" -For -Key "ExpectedShares.SomeShare.ReadWriteAccess" {
#			Test {
#				return $false;
#			}
#			Configure {
#				Write-Host "fake operation";
#			}
#		}
#		
#		Definition "Sample Disk" -Key "Host.ExpectedDisks.Data2Disk" {
#			Test {
#				return $false;
#			}
#			Configure {
#				Write-Host "fake operation";
#			}
#		}
#		
#		Definition "Sample Disk - VALUE" -Key "Host.ExpectedDisks.Data2Disk.VolumeLabel" {
#			Test {
#				return $false;
#			}
#			Configure {
#				Write-Host "fake operation";
#			}
#		}		
#	}
#}