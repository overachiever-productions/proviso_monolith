Set-StrictMode -Version 1.0;

filter Get-DataCollectorSetStatus {
	param (
		[string]$Name
	);
	
	try {
		# Sadly, this is total BS: https://docs.microsoft.com/en-us/powershell/scripting/whats-new/module-compatibility?view=powershell-7.1 
		#$state = Get-SMPerformanceCollector -CollectorName $Name -ErrorAction Stop;
		
		$query = logman query "$Name";
		if ($query -like "Data Collector Set was not found.") {
			return "<EMPTY>";
		}
		
		$regex = New-Object System.Text.RegularExpressions.Regex("Status:\s+(?<status>[^\r]+){1}", [System.Text.RegularExpressions.RegexOptions]::Multiline);
		$matches = $regex.Match($query);
		$status = "<EMPTY>";
		if ($matches) {
			$hack = $matches.Groups[1].Value;
			# not sure why... and... don't care at this point ... but instead of getting "Running" as the named capture... I'm getting EVERYTHING from "running" to the END of the stupid text... 
			#  I've tried multi-line, single-line, etc. ... 
			# so... this is a hack and ... meh. 
			$status = $hack.Substring(0, $hack.IndexOf(" ")).Trim();
		}
		
		return $status;
	}
	catch {
		$state = "<EMPTY>";
	}
	
	return $state;
}