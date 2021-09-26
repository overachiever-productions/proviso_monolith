Set-StrictMode -Version 1.0;

function Assert-ProvisoRequiredModule {
	param (
		[Parameter(Mandatory)]
		[string]$Name,
		[switch]$PreferProvisoRepo = $false,
		[switch]$DisableNameChecking = $false
	);
	
	$module = $null;
	if (-not ($PreferProvisoRepo)) {
		# TODO: possibly look at putting a timeout into play here... i.e., don't let this 'spin' against environments without an internet connection.
		$module = Find-Module -Name $Name -Repository PSGallery -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
	}
	
	if ($null -eq $module) {
		$module = Find-Module -Name $Name -Repository ProvisoRepo -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
	}
	
	if ($null -eq $module) {
		throw "Unable to Find Module $Name - after checking PSGallery and ProvisoRepo. Verify internet access (PSGallery) or that a copy of $Name exists in the ProvisoRepo.";
	}
	
	$inSession = $false;
	$inSessionOrInstalled = Get-Module -Name $Name;
	if ($null -eq $inSessionOrInstalled) {
		$inSessionOrInstalled = Get-Module -Name $Name -ListAvailable;
	}
	else {
		$inSession = $true;
	}
	
	$installNeeded = $false;
	if ($null -eq $inSessionOrInstalled) {
		$installNeeded = $true; # Not found in-session or on box, install from found/matched repo: 
	}
	else {
		$foundVersion = $module.Version;
		$inSessionOrInstalledVersion = $inSessionOrInstalled.Version;
		
		if ($inSessionOrInstalledVersion -lt $foundVersion) {
			$installNeeded = $true;
		}
	}
	
	if ($installNeeded) {
#		Install-Module -Name Proviso -Repository ProvisoRepo -Confirm:$false -Force;
#		Install-Module -Name PSFramework -Repository ProvisoRepo -Confirm:$false -Force;
#		Import-Module -Name Proviso -DisableNameChecking -Force;
#		Import-Module -Name PSFramework -Force;
		
		Install-Module -Name $Name -Repository $($module.Repository) -Confirm:$false -Force -WarningAction SilentlyContinue;
		Import-Module -Name $Name -Force -WarningAction SilentlyContinue -DisableNameChecking:$DisableNameChecking;
	}
}