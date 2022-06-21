Set-StrictMode -Version 1.0;

filter Enable-AlwaysOnAccessForSqlServerInstance {
	param (
		[Parameter(Mandatory)]
		[string]$SQLInstance
	);
	
	try {
		[ScriptBlock]$command = {
			param (
				[Parameter(Mandatory)]
				[string]$SQLInstance
			);
			
			$machineName = $env:COMPUTERNAME;
			if ("MSSQLSERVER" -eq "$SQLInstance") {
				$SQLInstance = "DEFAULT"
			}
			
			Enable-SqlAlwaysOn -Path "SQLSERVER:\SQL\$machineName\$SQLInstance" -Force;
		}
		
		Invoke-Command -ComputerName . $command -ArgumentList $SQLInstance;
	}
	catch {
		throw "Fatal Exception enabling SQLAlwaysOn: $_ `r`t$($_.ScriptStackTrace)";
	}
	
}


filter New-AvailabilityGroup {
	
}

filter Join-AvailabilityGroup {
	
}

filter New-AvailabilityGroupListener {
	# https://docs.microsoft.com/en-us/archive/blogs/alwaysonpro/create-listener-fails-with-message-the-wsfc-cluster-could-not-bring-the-network-name-resource-online
}