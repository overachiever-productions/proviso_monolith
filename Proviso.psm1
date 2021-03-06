<#

	List Repositories: 
		> Get-PSRepository


	Registering a Repo (e.g., LabRepo): 
		> Register-PSRepository -Name "LabRepo" -SourceLocation "\\storage.overachiever.net\Lab\ps-repository" -InstallationPolicy "Trusted";

	Publication: 
		- update the version if/as needed in the .psd1
		- run the following: 
			>  Publish-Module -Path "D:\Dropbox\Repositories\S4\S4 Tools\Proviso\" -Repository LabRepo                                   
			(note that publication is by DIRECTORY - not by .psm1...)

			Unpublish - in lab only = delete the .nupkg (i.e., there's no UnPublish command because you never know who/what (in the real world) might have taken a dependency on a module. 


	Installation: 
		> Install-Module -Name Proviso -Repository LabRepo

		> Import-Module Proviso

#>

$functionsPath = Join-Path -Path $PSScriptRoot -ChildPath 'functions/*.ps1';
$internalFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath 'internal/*.ps1';

$public = @(Get-ChildItem -Path $functionsPath -Recurse -ErrorAction Stop);
$internal = @(Get-ChildItem -Path $internalFunctionsPath -Recurse -ErrorAction Stop);
foreach ($file in @($public + $internal)) {
	try {
		. $file.FullName;
	}
	catch {
		throw "Unable to dot source [$($file.FullName)]";
	}
}

Export-ModuleMember -Function $public.BaseName;