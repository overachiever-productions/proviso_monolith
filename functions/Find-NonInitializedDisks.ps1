Set-StrictMode -Version 1.0;

function Find-NonInitializedDisks {
	Get-DiskDetails | Where-Object {
		$_.DriveLetter -eq "N/A"
	};
}