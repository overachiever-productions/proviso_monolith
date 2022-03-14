Set-StrictMode -Version 1.0;

<# 
	SCOPE: 
		A Surface is not a 'true function' - it doesn't DO anything. 
		Instead, it's a container for ordered script-blocks. 
		When run/executed, it creates a (clr) Proviso.Models.Surface object, which contains a list of hierarchical/ordered code bloxks
			that, in turn, will eventually be executed by the Process-Surface method via either the Validate-<SurfaceName> or Configure-<SurfaceName>
			proxies created as wrappers for validate or configure 'calls' against specific surfaces.

	NOTE: 
		Surface sub-funcs have been broken out to enable better PrimalSense while authoring. 
		The actual 'structure' or layout of a Surface and its sub-funcs is as follows: 

				function Surface {
					
					function Setup {}

					function Assertions {
						function Assert {
						}

						# optional, pre-defined assertions: 
						function Assert-UserIsAdminstrator{}
						function Assert-HostIsRunningWindows{}
						etc.
					}

					function Rebase {}

					function Aspect -Scope "xxx" {
						function Facet {
							function Expect {}
							function Test {} 
							function Configure {}
						}

						function Build {  # up to 1x per Aspect... 


						}

						function Deploy {
							
						}
					}
				}




	Import-Module -Name "D:\Dropbox\Repositories\proviso\" -DisableNameChecking -Force;


#>

# vNEXT: add error-handling/try-catches... 

filter Validate-SurfaceKey {
	param (
		[Parameter(Mandatory)]
		[string]$Key
	);
	
	$parts = $Key -split '\.';
	if ($parts.Count -gt 1) {
		throw "Invalid Surface Key: [$Key]. Surface Keys must be 'root' level keys - i.e., they can not be multi-part.";
	}
	
	if (-not (Is-ValidProvisoKey -Key $Key)) {
		throw "Invalid Surface Key: [$Key]. Key is NOT valid.";
	}
}

filter Validate-AspectKey {
	param (
		[Parameter(Mandatory)]
		[string]$AspectKey
	);
	
	$parts = $AspectKey -split '\.';
	if ($parts.Count -lt 2) {
		throw "Invalid Aspect Key: [$AspectKey]. Aspect Keys must be child-keys - i.e., they must be multi-part.";
	}
	elseif ($parts.Count -gt 4) {
		throw "Invalid Aspect Key: [$AspectKey]. Aspect Keys can not have more children/parts than 3.";
	}
	
	
	if (-not (Is-ValidProvisoKey -Key $AspectKey)) {
		throw "Invalid Aspect Key: [$AspectKey]. Key is NOT valid.";
	}
}

function Surface {
	param (
		[Parameter(Position = 0, ParameterSetName = "default")]
		[string]$Name,
		[Parameter(Mandatory, Position = 1, ParameterSetName = "default")]
		[ScriptBlock]$Scripts,
		[Switch]$For, # syntactic sugar only... i.e., allows a block of script to accompany a surface 'facet' - for increased context/natural-language
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Key
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Surface";
		Validate-SurfaceKey -Key $Key;
		
		$surfaceFileName = Split-Path -Path $MyInvocation.ScriptName -LeafBase;
		if ($null -eq $Name) {
			$Name = $surfaceFileName;
		}
		
		$surface = New-Object Proviso.Models.Surface($Name, $surfaceFileName, ($MyInvocation.ScriptName).Replace($ProvisoScriptRoot, ".."));
		if (-not ([string]::IsNullOrEmpty($Key))) {
			$surface.AddConfigKey($Key);
		}
	}
	
	process {
		
		& $Scripts;
	}
	
	end {
		
		$surface.Validate();
		$global:PVCatalog.AddSurface($surface);
	}
}

function Setup {
	param (
		[scriptblock]$SetupBlock
	);
	
	Validate-SurfaceBlockUsage -BlockName "Setup";
	
	$setup = New-Object Proviso.Models.Setup($SetupBlock, $Name);
	$surface.AddSetup($setup);
}

function Assertions {
	param (
		[ScriptBlock]$Assertions
	);
	
	Validate-SurfaceBlockUsage -BlockName "Assertions";
	
	# vNEXT: figure out how to constrain inputs here - as per: https://powershellexplained.com/2017-03-13-Powershell-DSL-design-patterns/#restricted-dsl
	# 		oddly, I can't use a ScriptBlock literal here - i.e., i THINK I could use a string, but not a block... so, MAYBE? convert the block to a string then 'import' it that way to ensure it's constrained?
	#			$validatedAssertions = [ScriptBlock]::Create("DATA -SupportedCommand Assert {$Assertions}");
	#			& $validatedAssertions
	& $Assertions;
}

function Assert {
	param (
		[Parameter(Position = 0)]
		[string]$Description,
		[Parameter(Position = 1)]
		[ScriptBlock]$AssertBlock,
		[Alias("Has", "For", "Exists")]
		[switch]$Is = $false,
		[Alias("HasNot", "DoesNotExist")]
		[switch]$IsNot = $false,
		[string]$FailureMessage = $null,
		[Alias("NotFatal", "UnFatal", "Informal", "")]
		[switch]$NonFatal = $false,
		[Alias("ConfigureOnly")]
		[switch]$AssertOnConfigureOnly = $false,
		[Alias("Skip", "DoNotRun")]
		[switch]$Ignored = $false
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Assert";
		
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
		
		try {
			$assertion = New-Object Proviso.Models.Assertion($Description, $Name, $AssertBlock, $FailureMessage, $NonFatal, $Ignored, $isNegated, $AssertOnConfigureOnly);
		}
		catch {
			throw "Invalid Assert. `rException: $_ `r`t$($_.ScriptStackTrace)";
		}
	}
	
	end {
		if (-not ($Ignored)) {
			$surface.AddAssertion($assertion);
		}
	}
}

function Assert-UserIsAdministrator {
	param (
		[string]$FailureMessage = "Current User is not a Member of the Administrators Group.",
		[Alias("ConfigureOnly")]
		[switch]$AssertOnConfigureOnly = $false,
		[Alias("Skip", "DoNotRun")]
		[Switch]$Ignored = $false
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Assert";
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
			
			$assertion = New-Object Proviso.Models.Assertion("Assert-IsAdministrator", $Name, $codeBlock, $FailureMessage, $false, $Ignored, $false, $AssertOnConfigureOnly);
		}
		catch {
			throw "Proviso Error - Exception creating Assert-UserIsAdministrator: `rException: $_ `r`t$($_.ScriptStackTrace)";
		}
	}
	
	end {
		if (-not ($Ignored)) {
			$surface.AddAssertion($assertion);
		}
	}
}

function Assert-ConfigIsStrict {
	param (
		[string]$FailureMessage = "Current Surface requires Host-Name and Target server to match before continuing.",
		[Alias("ConfigureOnly")]
		[switch]$AssertOnConfigureOnly = $false,
		[Alias("Skip", "DoNotRun")]
		[Switch]$Ignored = $false
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Assert";
	}
	
	process {
		if ($Ignored) {
			return;
		}
		
		[ScriptBlock]$codeBlock = {
			$targetHostName = $PVConfig.GetValue("Host.TargetServer");
			$currentHostName = [System.Net.Dns]::GetHostName();
			if ($targetHostName -ne $currentHostName) {
				return $false;
			}
		}
		
		$assertion = New-Object Proviso.Models.Assertion("Assert-ConfigIsStrict", $Name, $codeBlock, $FailureMessage, $false, $Ignored, $false, $AssertOnConfigureOnly);
	}
	
	end {
		if (-not ($Ignored)) {
			$surface.AddAssertion($assertion);
		}
	}
}

function Assert-HostIsWindows {
	param (
		[string]$FailureMessage = "Current Host is NOT running Windows.",
		[Alias("Skip", "DoNotRun")]
		[switch]$Ignored = $false,
		[Alias("ConfigureOnly")]
		[switch]$AssertOnConfigureOnly = $false,
		[switch]$Server = $false #,
		#[switch]$VerifyTargetOs = $false  # if true, then zip out to Host.OSSomethingSomething.WIndowsVersion or whatever, and pass THAT in as the windows version to validate against... 
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Assert";
		
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
			
			$assertion = New-Object Proviso.Models.Assertion("Assert-HostIsWindows", $Name, $codeBlock, $FailureMessage, $false, $Ignored, $false, $AssertOnConfigureOnly);
		}
		catch {
			throw "Proviso Error - Exception creating Assert-HostIsWindows: `rException: $_ `r`t$($_.ScriptStackTrace)";
		}
	}
	
	end {
		if (-not ($Ignored)) {
			$surface.AddAssertion($assertion);
		}
	}
}

function Assert-HasDomainCreds {
	param (
		[string]$FailureMessage = $null,
		[switch]$ForDomainJoin = $false,
		[switch]$ForClusterCreation = $false,
		[Alias("ConfigureOnly")]
		[switch]$AssertOnConfigureOnly = $false,
		#[switch]$ForAdditionOfLocalAdmins = $false, # see notes below about this PROBABLY NOT even being needed...
		[Alias("Skip", "DoNotRun")]
		[switch]$Ignored = $false
	)
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Assert";
		
		#$sum = @($ForDomainJoin, $ForClusterCreation, $ForAdditionOfLocalAdmins) | ForEach-Object -begin { $out = 0; } -Process { if ($_) {	$out += 1 }; } -end { return $out; };
		$sum = @($ForDomainJoin, $ForClusterCreation) | ForEach-Object -begin {
			$out = 0;
		} -Process {
			if ($_) {
				$out += 1
			};
		} -end {
			return $out;
		};
		
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
			
			$assertion = New-Object Proviso.Models.Assertion("Assert-HasDomainCreds", $Name, $codeBlock, $FailureMessage, $false, $Ignored, $false, $AssertOnConfigureOnly);
		}
		catch {
			throw "Proviso Error - Exception creating Assert-HasDomainCreds: `rException: $_ `r`t$($_.ScriptStackTrace)";
		}
	}
	
	end {
		if (-not ($Ignored)) {
			$surface.AddAssertion($assertion);
		}
	}
}

function Assert-IsDomainJoined {
	throw "Not Implemented"; # not sure this is needed or would make perfect sense. (EVEN for WSFC clusters, this isn't a GIVEN.)
}

function Assert-ProvisoResourcesRootDefined {
	param (
		[string]$FailureMessage = "Proviso Root Resources and assets path not defined.",
		[Alias("ConfigureOnly")]
		[switch]$AssertOnConfigureOnly = $false,
		[Alias("Skip", "DoNotRun")]
		[Switch]$Ignored = $false
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Assert";
	}
	
	process {
		if ($Ignored) {
			return;
		}
		
		try {
			[ScriptBlock]$codeBlock = {
				return $PVResources.RootSet;
			}
			
			$assertion = New-Object Proviso.Models.Assertion("Assert-ProvisoResourcesRootDefined", $Name, $codeBlock, $FailureMessage, $false, $Ignored, $false, $AssertOnConfigureOnly);
		}
		catch {
			throw "Proviso Error - Exception creating Assert-ProvisoResourcesRootDefined: `rException: $_ `r`t$($_.ScriptStackTrace)";
		}
	}
	
	end {
		if (-not ($Ignored)) {
			$surface.AddAssertion($assertion);
		}
	}
}

function Assert-SqlServerIsInstalled {
	param (
		[string]$FailureMessage = "SQL Server Configuration Surfaces cannot be run until all defined SQL Server instances are installed.",
		[Alias("ConfigureOnly")]
		[switch]$AssertOnConfigureOnly = $false,
		[Alias("Skip", "DoNotRun")]
		[Switch]$Ignored = $false
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Assert";
	}
	
	process {
		if ($Ignored) {
			return;
		}
		
		try {
			[ScriptBlock]$codeBlock = {
				# TODO: standardize calls into Get-provisoConfigGroupNames. I was doing "SQLServerInstallation.*" here and ... it returned nothing... 
				# 		i.e., need to probably just roll this func into the $PVConfig object itself ANYHOW... and then address parameter cleanup options there vs in callers (not sure what I was thinking)
				$instanceNames = $PVConfig.GetGroupNames("SQLServerInstallation");
				if ($instanceNames.Count -lt 1) {
					throw "Expected 1 or more instances - but none were defined at [SQLServerInstallation.*].";
				}
				
				$installedInstances = Get-ExistingSqlServerInstanceNames;
				
				foreach ($instance in $instanceNames) {
					if ($installedInstances -notcontains $instance) {
						throw "Expected SQL Server Instance [$instance] is not installed.";
					}
				}
			}
			
			$assertion = New-Object Proviso.Models.Assertion("Assert-SqlServerIsInstalled", $Name, $codeBlock, $FailureMessage, $false, $Ignored, $false, $AssertOnConfigureOnly);
		}
		catch {
			throw "Proviso Error - Exception creating Assert-SqlServerIsInstalled: `rException: $_ `r`t$($_.ScriptStackTrace)";
		}
	}
	
	end {
		if (-not ($Ignored)) {
			$surface.AddAssertion($assertion);
		}
	}
}

function Assert-AdminDbInstalled {
	param (
		[string]$FailureMessage = "AdminDb Configuration Surfaces cannot be run until the admindb has been deployed.",
		[Alias("ConfigureOnly")]
		[switch]$AssertOnConfigureOnly = $false,
		[Alias("Skip", "DoNotRun")]
		[Switch]$Ignored = $false
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Assert";
	}
	
	process {
		if ($Ignored) {
			return;
		}
		
		try {
			[ScriptBlock]$codeBlock = {
				$instanceNames = $PVConfig.GetGroupNames("AdminDb");
				if ($instanceNames.Count -lt 1) {
					throw "Expected 1 or more instances - but none were defined at [AdminDb.*].";
				}
				
				foreach ($instance in $instanceNames) {
					if ($PVConfig.GetValue("AdminDb.$instance.Deploy")) {
						$exists = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instance) "SELECT [name] FROM sys.databases WHERE [name] = 'admindb'; ").name;
						if (-not ($exists)) {
							return $false;
						}
					}
				}
				
				return $true;
			}
			
			$assertion = New-Object Proviso.Models.Assertion("Assert-SqlServerIsInstalled", $Name, $codeBlock, $FailureMessage, $false, $Ignored, $false, $AssertOnConfigureOnly);
		}
		catch {
			throw "Proviso Error - Exception creating Assert-AdminDbInstalled: `rException: $_ `r`t$($_.ScriptStackTrace)";
		}
	}
	
	end {
		if (-not ($Ignored)) {
			$surface.AddAssertion($assertion);
		}
	}
}

function Rebase {
	param (
		[scriptblock]$RebaseBlock
	);
	
	Validate-SurfaceBlockUsage -BlockName "Rebase";
	
	$rebase = New-Object Proviso.Models.Rebase($RebaseBlock, $Name);
	$surface.AddRebase($rebase);
}

function Aspect {
	param (
		[Parameter(Mandatory)]
		[ScriptBlock]$AspectBlock,
		[string]$Scope,
		[switch]$OrderDescending = $false,
		[string]$OrderByChildKey
	);
	
	Validate-SurfaceBlockUsage -BlockName "Aspect";
	$aspectKey = $Key;
	if ($null -ne $Scope) {
		$aspectKey += ".$Scope";
	}
	
	
	$ExpectBlock = $null; # Required as a declaration to allow the Expect{} func to set this (if it's defined/called/set)
	
	& $AspectBlock;
}

function Facet {
	param (
		[Parameter(Mandatory, Position = 0, ParameterSetName = "named")]
		[string]$Name,
		$Expect,
		[switch]$UsesBuild = $false,
		[Parameter(Mandatory, Position = 2, ParameterSetName = "named")]
		[ScriptBlock]$FacetBlock,
		[string]$For = "",
		[string]$ExpectKeyValue = $null,
		# expect a single, specific, key. e.g., -ExpectKeyValue "Host.FirewallRules.EnableICMP"
		[switch]$ExpectCurrentKeyValue = $false,
		# expect the current key value for Value or Group Keys e.g., if the key is "Host.LocalAdministrators", 'expect' an entry for each key-value. Whereas, if the key is "AdminDb.*", expect a value/key for each SQL Server instance (MSSQLSERVER, X3, etc.)
		[string]$ExpectChildKeyValue = $null,
		# e.g., -ExpectChildKeyValue "Enabled" would return the key for, say, AdminDb.RestoreTestJobs..... Enabled (i.e., parent/iterator + current child-key)
		[string]$IterationKey,
		# e.g., if the -Scope is "ExpectedDirectories.*", then -IterationKey could be "RawDirectories" or "VirtualSqlServerServiceAccessibleDirectories"
		[switch]$ExpectIterationKeyValue = $false,
		# e.g., if we're working through an -IterationKey of "RawDirectories" (for a -Scope of "ExpectedDirectories"), then we'd Expect one entry/value her for each 'Raw Directory' (or path) defined in the config
		[switch]$RequiresReboot = $false
	)
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Facet";
		
		$facetType = [Proviso.Enums.FacetType]::Simple;
		if ($Scope) {
			$trimmedScopeKey = $Scope -replace ".\*", "";
			
			if (-not (Is-ValidProvisoKey -Key $trimmedScopeKey)) {
				throw "Fatal Error. Aspect Scope for Facet [$Name] within Surface [$($surface.Name)] is invalid. Key [$Scope] is not valid.";
			}
			
			$keyType = Get-KeyType $trimmedScopeKey;
			
			switch ($keyType) {
				"Static" {
				}
				"Dynamic" {
					$facetType = [Proviso.Enums.FacetType]::Value;
				}
				"SqlInstance" {
					$facetType = [Proviso.Enums.FacetType]::Group;
				}
				"Complex" {
					$facetType = [Proviso.Enums.FacetType]::Compound;
				}
				default {
					throw
				}
			}
		}
		
		# additional, per type, validations:
		switch ($facetType) {
			Simple {
				# OrderBy operations can only be set by specific facet types: 
				if ($OrderByChildKey -or $OrderDescending) {
					throw "Aspects may NOT specify an -OrderByChildKey or -OrderDescending directive unless they specify -Scope arguments for configuration keys to evaluate.";
				}
			}
			Value {
				
			}
			Group {
				
			}
			Compound {
				
			}
		}
		
		Write-Host "$($surface.Name).$Name -> $facetType ";
	}
	
	process {
		$facet = New-Object Proviso.Models.Facet($surface, $Name, $facetType);
		
		if ($RequiresReboot) {
			$facet.SetRequiresReboot();
		}
		
		if ($ExpectKeyValue) {
			$facet.SetStaticKey($ExpectKeyValue);
			$facet.SetExpectAsStaticKeyValue(); # TODO: see if there's any reason to NOT combine these 2x calls down/into a single operation... 
		}
		
		switch ($facet.FacetType) {
			Simple {
			}
			Value {
				$facet.SetIterationKeyForValueAndGroupFacets($Scope);
				
				if ($ExpectCurrentKeyValue) {
					$facet.SetExpectAsCurrentIterationKeyValue();
				}
				
				if ($OrderDescending) {
					$facet.AddOrderDescending();
				}
			}
			Group {
				$facet.SetIterationKeyForValueAndGroupFacets($Scope);
				
				if ($ExpectCurrentKeyValue) {
					$facet.SetExpectAsCurrentIterationKeyValue();
				}
				
				if ($ExpectChildKeyValue) {
					$facet.SetExpectAsCurrentChildKeyValue($ExpectChildKeyValue);
				}
				
				if ($OrderByChildKey) {
					$facet.AddOrderByChildKey($OrderByChildKey);
				}
			}
			Compound {
				$facet.SetIterationKeyForValueAndGroupFacets($Scope);
				$facet.SetCompoundIterationValueKey($IterationKey);
				
				if ($ExpectCurrentKeyValue) {
					$facet.SetExpectAsCurrentIterationKeyValue();
				}
				
				if ($ExpectIterationKeyValue) {
					$facet.SetExpectAsCompoundKeyValue();
				}
				
				if ($OrderByChildKey) {
					$facet.AddOrderByChildKey($OrderByChildKey);
				}
			}
		}
		
		& $FacetBlock;
	}
	
	end {
		# -Expect is just 'syntactic sugar':
		if ($Expect -and ($null -eq $facet.Expectation)) {
			$script = "return '$Expect';";
			$ExpectBlock = [scriptblock]::Create($script);
			
			$facet.SetExpect($ExpectBlock);
		}
		
		if ($UsesBuild -and ($null -eq $facet.Configure)) {
			#$surface.VerifyCanUseBuild(); # throws if there aren't BUILD/DEPLOY funcs. 
			$facet.SetUsesBuild();
		}
		
		$surface.AddFacet($facet);
	}
}

function Expect {
	#region vNEXT
	# vNEXT: It MAY (or may not) make sense to allow MULTIPLE Expects. 
	# 		for example, TargetDomain ... could be "" or "WORKGROUP". Both answers are acceptable. 
	# 	there are 2x main problems with this proposition, of course: 
	#		1. How do I end up tweaking the .config to allow 1 or MORE values? (guess I could make arrays? e.g., instead of TargetDomain = "scalar" it could be TargetDomain = @("", "WORKGROUP")
	# 		2. I then have to address how to compare one return value against multiple options. 
	# 			that's easy on the surface - but a bit harder under the covers... 
	# 				specifically:
	# 					- does 1 match of actual vs ALL possibles yield a .Matched = true? 
	# 					or does .Matched = true require that ALL values were matches? ... 
	# 				i.e., this starts to get messy/ugly. 
	# 		3. Yeah... the third out of 2 problems is ... that this tends to overly complicate things... it could spiral out of control quickly.
	# 	all of the above said... IF I end up going with 'multiples', then I think the approach would be: Expect { x } OrExpect { z } OrExpect { y }
	#endregion
	param (
		[ScriptBlock]$ExpectBlock,
		[string]$That # syntactic sugar
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Expect";
	}
	
	process {
		$facet.SetExpect($ExpectBlock);
	}
	
	end {
		
	}
}

function Test {
	param (
		[ScriptBlock]$TestBlock
	);
	
	Validate-SurfaceBlockUsage -BlockName "Test";
	
	$facet.SetTest($TestBlock);
}

function Configure {
	param (
		[ScriptBlock]$ConfigureBlock
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Configure";
		
		if ($UsesBuild) {
			throw "Invalid Argument. Facets can use EITHER a Configure{} block OR the -UsesBuild parameter (not both).";
		}
	}
	
	process {
		$facet.SetConfigure($ConfigureBlock);
	}
	
	end {
		
	}
}

function Build {
	param (
		[scriptblock]$BuildBlock
	);
	
	Validate-SurfaceBlockUsage -BlockName "Build";
	
	$build = New-Object Proviso.Models.Build($BuildBlock, $Name);
	$surface.AddBuild($build);
}

function Deploy {
	param (
		[scriptblock]$DeployBlock
	);
	
	Validate-SurfaceBlockUsage -BlockName "Deploy";
	
	$deploy = New-Object Proviso.Models.Deploy($DeployBlock, $Name);
	$surface.AddDeploy($deploy);
}