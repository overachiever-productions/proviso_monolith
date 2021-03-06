Set-StrictMode -Version 1.0;

function Remove-OldDataCollectorFiles {
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$DataCollectorName,
		[Parameter(Mandatory = $false)]
		[int]$DaysWorthOfLogsToKeep = 45,
		[Parameter(Mandatory = $false)]
		[string]$RootFilePath = "C:\PerfLogs\Admin\"
	);
	
	$threshold = (Get-Date).AddDays(0 - $DaysWorthOfLogsToKeep);
	$directory = Join-Path -Path $RootFilePath -ChildPath $DataCollectorName;
	
	Get-ChildItem $directory | Where-Object CreationTime -lt $threshold | Remove-Item -Force;
}