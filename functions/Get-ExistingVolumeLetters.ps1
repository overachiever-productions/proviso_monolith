Set-StrictMode -Version 1.0;

function Get-ExistingVolumeLetters {
	Get-Volume | Where-Object {
		$_.DriveLetter -ne $null
	} | Select-Object -ExpandProperty DriveLetter;
}