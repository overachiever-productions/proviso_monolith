

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