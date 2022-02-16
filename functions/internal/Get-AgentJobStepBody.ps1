Set-StrictMode -Version 1.0;

filter Get-AgentJobStepBody {
	param (
		[Parameter(Mandatory)]
		[string]$SqlServerAgentJob,
		[Parameter(Mandatory)]
		[string]$JobStepName,
		[Parameter(Mandatory)]
		[string]$SqlServerInstanceName
	);
	
	$jobId = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $SqlServerInstanceName) "SELECT [job_id] FROM msdb.dbo.[sysjobs] WHERE [name] = N'$SqlServerAgentJob'; ").job_id;
	
	if (-not ($jobId)) {
		return "<EMPTY>";
	}
	
	$body = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT 
			[command] 
		FROM 
			[msdb].dbo.[sysjobsteps] 
		WHERE 
			[step_name] = N'$JobStepName' 
			AND [job_id] = '$jobId'; ").command;
	
	if ($body) {
		return $body;
	}
	
	return "<EMPTY_BODY>";
}