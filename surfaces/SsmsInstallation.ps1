Set-StrictMode -Version 1.0;

Surface SsmsInstallation -Target "SqlServerManagementStudio" {
	Assertions {
		
	}
	
	Aspect {
		Facet "SSMS Installed" -Key "InstallSsms" -ExpectKeyValue {
			Test {
				# Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders
				# Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server Management Studio
				# hmm
				# Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server Management Studio\18
				
				# for now, just check in the default location:
				
				$targetPath = $PVConfig.GetValue("SqlServerManagementStudio.InstallPath");
				$exePath = Join-Path -Path $targetPath -ChildPath "Common7\IDE\Ssms.exe";
				
				return Test-Path $exePath;
			}
			Configure {
				$binaryKey = $PVConfig.GetValue("SqlServerManagementStudio.Binary");
				$binaryPath = $PVResources.GetSsmsBinaries($binaryKey);
				if (-not (Test-Path $binaryPath)) {
					throw "SSMS Binaries were not located for defined key: [$binaryKey] at path [$binaryPath]. Cannot continue with SSMS installation.";
				}
				
				$installPath = $PVConfig.GetValue("SqlServerManagementStudio.InstallPath");
				[bool]$installAzure = $PVConfig.GetValue("SqlServerManagementStudio.IncludeAzureStudio");
				
				Install-SqlServerManagementStudio -Binaries $binaryPath -InstallPath $installPath -IncludeAzureDataStudio:$installAzure;
			}
		}
		
#		Facet "SSMS Version" {
#			Expect {
#				# PRESUMABLY, I could connect to the binary/install.exe and ... run a quick 'test' against the .exe via a command ... to see the version? 
#				#    if not that ... then, maybe something from the equivalent of Properties > Details... 
#			}
#			Test {
#				# presumably, there's a simple registry key somewhere or ... i can grab the info i need from the .exe (look at details/etc.0 or ... whatever). 	
#				# Yup... 		C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe > right-click > Properties > Details ... shows the current version.
#			}
#			Configure {
#				
#			}
#		}
	}
}