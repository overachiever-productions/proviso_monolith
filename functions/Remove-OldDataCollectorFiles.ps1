Set-StrictMode -Version 1.0;

function Remove-OldDataCollectorFiles {
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$Name,
		[Parameter(Mandatory = $false)]
		[int]$RetentionDays = 45,
		[Parameter(Mandatory = $false)]
		[string]$RootPath = "C:\PerfLogs\"
	);
	
	$threshold = (Get-Date).AddDays(0 - $RetentionDays);
	$directory = Join-Path -Path $RootPath -ChildPath $Name;
	
	Get-ChildItem $directory | Where-Object CreationTime -lt $threshold | Remove-Item -Force;
}