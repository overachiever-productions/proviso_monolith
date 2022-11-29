Set-StrictMode -Version 1.0;

# Refactor: this should probably be $PVFormatter
$script:Formatter = [Proviso.Formatter]::Instance;

# Each call to Summarize (func) sets this value to 0. 
#    whereas each call into Formatter.GetSurfaceId() ... increments by 1 and then converts # to alpha... 
[int]$script:fc1dd0f3SummaryCounter = 0;
[hashtable]$script:fc1dd0f3SummaryIds = @{};
[ScriptBlock]$GetSurfaceId = {
	param (
		[Parameter(Mandatory)]
		[System.Guid]$ProcessingId
	);
	
	if ($script:fc1dd0f3SummaryIds.ContainsKey($ProcessingId)) {
		$output = $script:fc1dd0f3SummaryIds[$ProcessingId];
	}
	else {
		$script:fc1dd0f3SummaryCounter++;
		$current = $script:fc1dd0f3SummaryCounter + 64;
		$output = [char]$current;
		
		$script:fc1dd0f3SummaryIds.Add($ProcessingId, $output);
	}
	
	return " $output.";
}

[ScriptBlock]$ResetSurfaceIds = {
	[int]$script:fc1dd0f3SummaryCounter = 0;
	[hashtable]$script:fc1dd0f3SummaryIds = @{};
}


$script:Formatter | Add-Member -MemberType ScriptMethod -Name GetSurfaceId -Value $GetSurfaceId;
$script:Formatter | Add-Member -MemberType ScriptMethod -Name ResetSurfaceIds -Value $ResetSurfaceIds;