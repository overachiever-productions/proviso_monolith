Set-StrictMode -Version 1.0;

function Get-ExistingVolumesByLetter {
	$drives = Get-Volume | Where-Object {
		$_.DriveLetter -ne $null
	} | Select-Object -ExpandProperty DriveLetter;
	
	return $drives;
}