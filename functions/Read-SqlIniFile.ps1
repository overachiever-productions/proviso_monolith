Set-StrictMode -Version 1.0;

function Read-SqlIniFile {
	param (
		[Parameter(Mandatory = $true)]
		[string]$FilePath
	)
	
	if (!(Test-Path -Path $FilePath)) {
		throw "File Path specified for SQL Server Installation .ini is invalid. Terminating. Path Specified: $($FilePath).";
	}
	
	$data = @{};
	$data["_ORDINALS"] = @{};
	$data["_GROUPS"] = @{};
	
	[int]$ordinal = 0;
	
	switch -regex -file $FilePath {
		"^\[(.+)\]" # Group
		{
			$ordinal++;
			$group = $matches[1];
			$data[$group] = @{};
			$data["_GROUPS"][$ordinal] = $group;
		}
		"^(?!;)(.+)\s*=\s*(.*)" # Entry
		{
			$ordinal++;
			$name = $matches[1];
			$value = $matches[2].Trim();
			$data[$group][$name] = $value;
			$data["_ORDINALS"][$ordinal] = "$($group).$($name)";
		}
	}
	
	$output = [PSCustomObject]$data;
	
	return $output;
}