Set-StrictMode -Version 1.0;

# NOTE: Requires AWS/S3 PowerShell Module. 
#   https://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-set-up-windows.html


function Copy-ConsolidatedTraceFilesFromS3 {
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$BucketName,
		[Parameter(Mandatory = $true)]
		[string]$TargetS3FilesPrefix, # will grab any files matching the prefix in question... 
		[Parameter(Mandatory = $true)]
		[string]$LocalRootPath,
		[Amazon.Runtime.AWSCredentials]$Creds
	);
	
	$targetFiles = Get-S3Object -BucketName $BucketName -Prefix $TargetS3FilesPrefix;
	
	foreach ($file in $targetFiles){
		$fileName = Split-Path -Path $file.Key -Leaf;
		
		$savedPath = Join-Path -Path $LocalRootPath -ChildPath $fileName;
		
		Read-S3Object -BucketName $BucketName -Key $file.Key -File $savedPath -Credential $Creds;
		#Write-Host "BucketName: $BucketName -> -Key $($file.Key)";
	}
}