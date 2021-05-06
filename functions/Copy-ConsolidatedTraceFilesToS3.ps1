Set-StrictMode -Version 1.0;

# NOTE: Requires AWS/S3 PowerShell Module. 
#   https://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-set-up-windows.html

# example of Write-S3Object:  Write-S3Object -BucketName "xxx-database-backup" -Key "transfer\trace_files\NA1\xxxx" -File "C:\PerfLogs\Admin\Consolidated\SERVERx_Performance Counter2021-04-01_00123.csv"

	<#			vNEXT ... allow optional END date and Start dates as parameters:
		[Parameter(Mandatory = $true)]
		[System.DateTime]$StartDate,
		[System.DateTime]$EndDate = 
			
			FODDER:
		
				https://stackoverflow.com/questions/27389939/how-do-i-pass-datetime-as-a-parameter-in-powershell
				https://stackoverflow.com/questions/16297808/passing-datetime-as-a-parameter
				https://stackoverflow.com/questions/39157239/powershell-script-pass-date-custom-format-as-parameter
	#>


<# 

	Example Execution: 
			> Copy-ConsolidatedTraceFilesToS3 -BucketName "ts-database-backup" -S3UploadedFilesPathPrefix "transfer\trace_files\NA1\" -NumberOfRecentFilesToUpload 15;

#>


function Copy-ConsolidatedTraceFilesToS3 {
	param (
		[string]$TraceFileRoot = "C:\PerfLogs\Admin\Consolidated\",
		[Parameter(Mandatory = $true)]
		[string]$BucketName,
		[Parameter(Mandatory = $true)]
		[string]$S3UploadedFilesPathPrefix,
		[int]$NumberOfRecentFilesToUpload = 15   # vNEXT... will allow either this or between start/end. 
	);
	

	# identify files: 
	$targetFiles = Get-ChildItem -Path $TraceFileRoot | Sort-Object CreationTime -Descending | Select-Object -First $NumberOfRecentFilesToUpload;
	
	foreach ($file in $targetFiles) {
		$fileName = $file.Name;
		$key = Join-Path -Path $S3UploadedFilesPathPrefix -ChildPath $fileName;
		
		try {
			Write-S3Object -BucketName $BucketName -Key $key -File $file.FullName;
		}
		catch {
			Write-Host $_;
		}
		
	}
}