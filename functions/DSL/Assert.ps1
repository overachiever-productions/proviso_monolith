Set-StrictMode -Version 1.0;

function Assert {
	param (
		[Parameter(Position = 0)]
		[string]$Description,
		[Parameter(Position = 1)]
		[ScriptBlock]$AssertBlock,
		[Alias("Has","For","Exists")]
		[Switch]$Is = $false,
		[Alias("HasNot", "DoesNotExist")]
		[Switch]$IsNot = $false,
		[string]$FailureMessage = $null,
		[Alias("NotFatal", "UnFatal", "Informal", "")]
		[Switch]$NonFatal = $false,
		[Alias("Skip", "DoNotRun")]
		[Switch]$Ignored = $false
	);
	
	begin {
		Validate-FacetBlockUsage -BlockName "Assert";
		
		if ($Is -and $IsNot) {
			# vNEXT: look at using $MyInvocation and/or other meta-data to determine WHICH alias was used and throw with those terms vs generic -Is/-IsNot:
			throw "Invalid Argument. The switches -Is (and aliases -Has, -For, -Exists) cannot be used concurrently with -IsNot (or aliases -HasNot, -DoesNotExist). An Assert is either true or false.";
		}
		
		[bool]$isNegated = $false;
		if ($IsNot) {
			$isNegated = $true;
		}
	}
	
	process {
		if ($Ignored) {
			return;
		}
		
		try{
			$assertion = New-Object Proviso.Models.Assertion($Description, $Name, $AssertBlock, $FailureMessage, $NonFatal, $Ignored, $isNegated);
		}
		catch {
			throw "Invalid Assert. `rException: $_ `r`t$($_.ScriptStackTrace)";
		}
	}
	
	end {
		if (-not ($Ignored)) {
			$facet.AddAssertion($assertion);
		}
	}
}

function Assert-UserIsAdministrator {
	param(
		[string]$FailureMessage = "Current User is not a Member of the Administrators Group.",
		[Alias("Skip", "DoNotRun")]
		[Switch]$Ignored = $false
	);
	
	begin {
		Validate-FacetBlockUsage -BlockName "Assert";
	}
	
	process {
		if ($Ignored) {
			return;
		}
		
		try {
			[ScriptBlock]$codeBlock = {
				$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
				$admins = Get-LocalGroupMember -Group Administrators | Select-Object -Property "Name";
				
				if ($admins.Name -contains $currentUser) {
					return $true;
				}
				
				return $false;
			}
			
			$assertion = New-Object Proviso.Models.Assertion("Assert-IsAdministrator", $Name, $codeBlock, $FailureMessage, $false, $Ignored, $false);
		}
		catch {
			throw "Proviso Error - Exception creating Assert-UserIsAdministrator: `rException: $_ `r`t$($_.ScriptStackTrace)";
		}
	}
	
	end {
		if (-not ($Ignored)) {
			$facet.AddAssertion($assertion);
		}
	}
}

function Assert-HostIsWindows {
	param (
		[string]$FailureMessage = "Current Host is NOT running Windows.",
		[Alias("Skip", "DoNotRun")]
		[switch]$Ignored = $false,
		[switch]$Server = $false#,
		#[switch]$VerifyTargetOs = $false  # if true, then zip out to Host.OSSomethingSomething.WIndowsVersion or whatever, and pass THAT in as the windows version to validate against... 
	);
	
	begin {
		Validate-FacetBlockUsage -BlockName "Assert";
		
#		$sum = @($Server2016, $Server2019, $Server2022) | ForEach-Object -begin { $out = 0; } -Process { if ($_) {	$out += 1 }; } -end { return $out; };
#		if ($sum -gt 1) {
#			throw "Invalid Argument. Only one specific Server version switch (e.g., -Server2022 or -Server2019) can be specified at a time.";
#		}
	}
	
	process {
		
		try {
			[string]$codeTemplate = '$os = (Get-ChildItem -Path Env:\POWERSHELL_DISTRIBUTION_CHANNEL).Value;
			if ($os -like "*Windows*") {
				return $true;
			}
			
			return $false; ';
			
			if ($Server) {
				$codeTemplate = $codeTemplate -replace "Windows", "Windows Server";
			}
			
#			if ($Server2016) {
#				$codeTemplate = $codeTemplate -replace "Windows", "Windows Server 2016";
#			}
#			
#			if ($Server2019) {
#				$codeTemplate = $codeTemplate -replace "Windows", "Windows Server 2019";
#			}
#			
#			if ($Server2022) {
#				$codeTemplate = $codeTemplate -replace "Windows", "Windows Server 2022";
#			}
			
			[ScriptBlock]$codeBlock = [scriptblock]::Create($codeTemplate);
			
			$assertion = New-Object Proviso.Models.Assertion("Assert-HostIsWindows", $Name, $codeBlock, $FailureMessage, $false, $Ignored, $false);
		}
		catch {
			throw "Proviso Error - Exception creating Assert-HostIsWindows: `rException: $_ `r`t$($_.ScriptStackTrace)";
		}
	}
	
	end {
		if (-not ($Ignored)) {
			$facet.AddAssertion($assertion);
		}
	}
}

function Assert-HasDomainCreds {
	param (
		[string]$FailureMessage = $null,
		[switch]$ForDomainJoin = $false,
		[switch]$ForClusterCreation = $false,
		#[switch]$ForAdditionOfLocalAdmins = $false, # see notes below about this PROBABLY NOT even being needed...  
		[Alias("Skip", "DoNotRun")]
		[switch]$Ignored = $false
	)
	
	begin {
		Validate-FacetBlockUsage -BlockName "Assert";
		
		#$sum = @($ForDomainJoin, $ForClusterCreation, $ForAdditionOfLocalAdmins) | ForEach-Object -begin { $out = 0; } -Process { if ($_) {	$out += 1 }; } -end { return $out; };
		$sum = @($ForDomainJoin, $ForClusterCreation) | ForEach-Object -begin { $out = 0; } -Process { if ($_) {	$out += 1 }; } -end { return $out; };
		
		if ($sum -gt 1) {
			throw "Invalid Argument. Only one specific 'for' reason/switch can be specified at a time.";
		}
	}
	
	process {
		
		try {
			[ScriptBlock]$codeBlock = {
				if (-not ($PVDomainCreds.CredentialsSet)) {
					throw "Domain Credentials not set/present.";
				}
			};
			
			if ($ForDomainJoin) {
				if ($null -eq $FailureMessage) {
					$FailureMessage = "Domain Credentials are Required for Domain-Join (and Pre-validation) purposes.";
				}
				
				[ScriptBlock]$codeBlock = {
					$targetDomain = $PVConfig.GetValue("Host.TargetDomain");
					$currentDomain = (Get-CimInstance Win32_ComputerSystem).Domain;
					if ($currentDomain -eq "WORKGROUP") {
						$currentDomain = "";
					}
					
					if ($targetDomain -ne $currentDomain) {
						if (-not ($PVDomainCreds.CredentialsSet)) {
							throw "Domain Credentials not set/present.";
						}
					}
				};
			}
			
			if ($ForClusterCreation) {
				if ($null -eq $FailureMessage) {
					$FailureMessage = "Domain Credentials are Required for Cluster Creation and/or CNO object creation permissions.";
				}
			}
			
			# TODO: Not sure this even NEEDs its own $codeBlock because I'm NOT 100% sure I even need Domain-Admin perms to either a) verify a domain account or b) add them to the local box
			#   so, disabling this for now... can re-add if/as needed. 
#			if ($ForAdditionOfLocalAdmins) {
#				if ($null -eq $FailureMessage) {
#					$FailureMessage = "Domain Credentials are Required for Addition of domain users as members of the Local Administrators Group.";
#				}
#				
#				[ScriptBlock]$codeBlock = {
#					[string[]]$targetAdmins = $PVConfig.GetValue("Host.LocalAdministrators");
#					
#					$hostName = [System.Net.Dns]::GetHostName();
#					
#					$domainsUsersFound = $false;
#					foreach ($admin in $targetAdmins) {
#						[string[]]$parts = $admin -split "\";
#						if ($parts.Count -gt 1) {
#							if ($parts[0] -ne $hostName) {
#								$domainsUsersFound = $true;
#							}
#						}
#					}
#					
#					if ($domainsUsersFound) {
#						if (-not ($PVDomainCreds.CredentialsSet)) {
#							throw "Domain Credentials not set/present.";
#						}
#					}
#				};
#			}
			
			$assertion = New-Object Proviso.Models.Assertion("Assert-HasDomainCreds", $Name, $codeBlock, $FailureMessage, $false, $Ignored, $false);
		}
		catch {
			throw "Proviso Error - Exception creating Assert-HasDomainCreds: `rException: $_ `r`t$($_.ScriptStackTrace)";
		}
	}
	
	end {
		if (-not ($Ignored)) {
			$facet.AddAssertion($assertion);
		}
	}
}

function Assert-IsDomainJoined {
	throw "Not Implemented";  # not sure this is needed or would make perfect sense. (EVEN for WSFC clusters, this isn't a GIVEN.)
}

function Assert-ProvisoResourcesRootDefined {
	param (
		[string]$FailureMessage = "Proviso Root Resources and assets path not defined.",
		[Alias("Skip", "DoNotRun")]
		[Switch]$Ignored = $false
	);
	
	begin {
		Validate-FacetBlockUsage -BlockName "Assert";
	}
	
	process {
		if ($Ignored) {
			return;
		}
		
		try {
			[ScriptBlock]$codeBlock = {
				return $PVResources.RootSet;
			}
			
			$assertion = New-Object Proviso.Models.Assertion("Assert-ProvisoResourcesRootDefined", $Name, $codeBlock, $FailureMessage, $false, $Ignored, $false);
		}
		catch {
			throw "Proviso Error - Exception creating Assert-ProvisoResourcesRootDefined: `rException: $_ `r`t$($_.ScriptStackTrace)";
		}
	}
	
	end {
		if (-not ($Ignored)) {
			$facet.AddAssertion($assertion);
		}
	}
}