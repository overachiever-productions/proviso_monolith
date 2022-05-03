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

function Surface {
	param (
		[Parameter(Position = 0, ParameterSetName = "default")]
		[string]$Name,
		[Parameter(Mandatory, Position = 1, ParameterSetName = "default")]
		[ScriptBlock]$Scripts,
		[ValidateNotNullOrEmpty()]
		[string]$Target   # i.e., the surface or root-key we're targetting
	);
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Surface";
		
		$surfaceFileName = Split-Path -Path $MyInvocation.ScriptName -LeafBase;
		if ($null -eq $Name) {
			$Name = $surfaceFileName;
		}
		
		$surface = New-Object Proviso.Models.Surface($Name, $surfaceFileName, ($MyInvocation.ScriptName).Replace($ProvisoScriptRoot, ".."));
		if (-not ([string]::IsNullOrEmpty($Target))) {
			$surface.AddConfigKey($Target);
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
		[Alias("Skip", "DoNotRun")]
		[switch]$Ignored = $false
	)
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Assert";
		
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
		[string]$SurfaceTarget = $null,
		[string]$FailureMessage = "SQL Server Configuration Surfaces cannot be run until SQL Server instances are installed.",
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
			
			[ScriptBlock]$codeBlock = $null;
			
			if ($SurfaceTarget) {
				
				
				# This 'has' to be dynamically created - to get around the need to pass $SurfaceTarget around inside as a 'string'... 
				# TODO: verify that this is working as expected ... i.e., what's it doing for other variable names? i.e., is the string output what I expect it to be? 
				$codeBlockAsString = '$installedInstanceNames = Get-ExistingSqlServerInstanceNames;

$targetInstancenames = $PVConfig.GetSqlInstanceNames("$SurfaceTarget");
if (($null -eq $targetInstancenames) -or ($targetInstancenames.Count -lt 1)) {{
	throw "Expected ONE or more SQL Server Instance Names defined within Configuration Surface [$SurfaceTarget] - but none were defined.";
}}

foreach ($targetInstance in $targetInstancenames) {{
	if ($installedInstanceNames -notcontains $targetInstance) {{
		throw "Expected SQL Server Instance [$targetInstance] is NOT installed.";
	}}
}}
';
				[ScriptBlock]$codeBlock = [ScriptBlock]::Create($codeBlockAsString);
			}
			else {
				[ScriptBlock]$codeBlock = {
					$installedInstanceNames = Get-ExistingSqlServerInstanceNames;
					
					if (($null -eq $installedInstanceNames) -or ($installedInstanceNames.Count -lt 1)) {
						throw "No Installed SQL Server Instances were Detected.";
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
				$configDefinedSqlInstances = $PVConfig.GetSqlInstanceNames("AdminDb");
				
				if (($null -eq $configDefinedSqlInstances) -or ($configDefinedSqlInstances.Count -lt 1)) {
					throw "Expected one or more SQL Server Instances to be defined for AdminDb surface configuration/targets - but NONE were found.";
				}
				
				foreach ($targetInstance in $configDefinedSqlInstances) {
					$exists = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $targetInstance) "SELECT [name] FROM sys.databases WHERE [name] = 'admindb'; ").name;
					if (-not ($exists)) {
						return $false;
					}
					
					# TODO / vNEXT: can provide an -RequiredVersion or something similar ... which'll zip in to $targetInstance.admindb.dbo.version_history and get the current/latest version. 
				}
				
				return $true;
			};
			
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

function Assert-WsfcComponentsInstalled {
	param (
		[string]$FailureMessage = "WSFC Components must be installed to validate and/or configure Cluster Components.",
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
				$installed = (Get-WindowsFeature -Name Failover-Clustering).InstallState;
				
				if ($installed -ne "Installed") {
					return $false;
				}
			};
			
			$assertion = New-Object Proviso.Models.Assertion("Assert-WsfcComponentsInstalled", $Name, $codeBlock, $FailureMessage, $false, $Ignored, $false, $false);
		}
		catch {
			throw "Proviso Error - Exception creating Assert-WsfcComponentsInstalled: `rException: $_ `r`t$($_.ScriptStackTrace)";
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
	
	$aspectKey = $Target;
	if(-not([string]::IsNullOrEmpty($Scope))) {
		$aspectKey += ".$Scope";
	}
	if (-not ([string]::IsNullOrEmpty($aspectKey))) {
		$aspectKey = Ensure-ProvisoConfigKeyIsNotImplicit -Key $aspectKey;
	}
	
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
		[string]$Key = "",
		[string]$FullKey = "",
		[switch]$NoKey = $false,
		[switch]$ExpectKeyValue = $false,
		[switch]$ExpectIteratorValue = $false,
		[string]$Proctor = "",
		[string]$ElideWhenExpectIs = "",
		[string]$ElideWhenProctorIs = "",
		[switch]$RequiresReboot = $false
	)
	
	begin {
		Validate-SurfaceBlockUsage -BlockName "Facet";
		
		# determine key/key-type for current facet: 
		$facetKey = $null;
		$facetType = $null;
		if (-not ($NoKey)) {
			if ($FullKey) {
				$facetKey = Ensure-ProvisoConfigKeyIsNotImplicit -Key $FullKey;
			}
			else {
				$facetKey = "$($aspectKey).$Key";
			}
			
			$facetKey = Ensure-ProvisoConfigKeyIsFormattedForObjects -Key $facetKey;
				
			if (-not (Is-ValidProvisoKey -Key $facetKey)) {
				throw "Invalid Configuration Key [$facetKey] found in Surface [$($surface.Name)] and Facet of [$Name].";
			}
			
			$stringFacetType = Get-FacetTypeByKey -Key $facetKey;
			$facetType = [Proviso.Enums.FacetType]$stringFacetType;
		}
		else {
			if ([string]::IsNullOrEmpty($aspectKey)) {
				$facetType = [Proviso.Enums.FacetType]::NonKey;	
			}
			else {
				$facetType = Get-FacetTypeByKey -Key $aspectKey;
				$facetKey = $aspectKey;
			}
		}
	}
	
	process {
		$facet = New-Object Proviso.Models.Facet($surface, $Name, $facetType, $facetKey);
		
		if ($RequiresReboot) {
			$facet.RequiresReboot = $true;
		}
		
		# aspect-level order-by directives:
		if ($OrderByChildKey) {
			if ($facetType -notin @("Object", "OjectArray")) {  # crazy that I can just compare strings like this (when it's an enum). 
				throw "The -OrderByChildKey switch can ONLY be used with configuration sections that yield multiple outputs/objects (i.e., Disks, Adapters, etc.).";
			}
			
			# TODO: Verify that the OrderBy key is legit... 
			$facet.OrderByChildKey = $OrderByChildKey;
		}
		if ($OrderDescending) {
			if ($facetType -notin @("Object", "OjectArray")) {
				throw "The -OrderDescending switch can ONLY be used with configuration sections that yield multiple outputs/objects (i.e., Disks, Adapters, etc.).";
			}
			
			$facet.OrderDescending = $true;
		}
		
		# Expects (other than code blocks):
		if (-not ($facet.ExpectIsSet) -and $ExpectKeyValue) {
			$facet.SetExpectForKeyValue();
		}
		if (-not ($facet.ExpectIsSet) -and $ExpectIteratorValue) {
			$facet.SetExpectForIteratorValue();
		}
		if (-not ($facet.ExpectIsSet) -and $Expect) { # The -Expect (switch) is just 'syntactic sugar':
			$script = "return '$Expect';";
			$ExpectBlock = [scriptblock]::Create($script);
			
			$facet.SetExpect($ExpectBlock);
		}
		
		& $FacetBlock;
	}
	
	end {
		if ($UsesBuild -and ($null -eq $facet.Configure)) {
			$facet.UsesBuild = $true;
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