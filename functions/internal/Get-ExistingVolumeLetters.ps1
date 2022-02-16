Set-StrictMode -Version 1.0;

function Get-ExistingVolumeLetters {
	Get-Volume | Where-Object {
		$_.DriveLetter -ne $null
	} | Sort-Object -Property DriveLetter | Select-Object -ExpandProperty DriveLetter;
}