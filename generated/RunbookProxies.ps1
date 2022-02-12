Set-StrictMode -Version 1.0; 

#-------------------------------------------------------------------------------------
# Tests
#-------------------------------------------------------------------------------------
function Evaluate-Tests {
	Validate-MethodUsage -MethodName "Evaluate";
	Execute-Runbook -RunbookName "Tests" -Operation Evaluate;
}

function Provision-Tests {
	param(
		[switch]$AllowReboot = $false, 
		[switch]$AllowSqlRestart = $false
	);

	Validate-MethodUsage -MethodName "Provision";
	Execute-Runbook -RunbookName "Tests" -Operation Provision;
}

#-------------------------------------------------------------------------------------
# ServerInitialization
#-------------------------------------------------------------------------------------
function Evaluate-ServerInitialization {
	Validate-MethodUsage -MethodName "Evaluate";
	Execute-Runbook -RunbookName "ServerInitialization" -Operation Evaluate;
}

function Provision-ServerInitialization {
	param(
		[switch]$AllowReboot = $false, 
		[switch]$AllowSqlRestart = $false
	);

	Validate-MethodUsage -MethodName "Provision";
	Execute-Runbook -RunbookName "ServerInitialization" -Operation Provision;
}

#-------------------------------------------------------------------------------------
# ServerConfiguration
#-------------------------------------------------------------------------------------
function Evaluate-ServerConfiguration {
	Validate-MethodUsage -MethodName "Evaluate";
	Execute-Runbook -RunbookName "ServerConfiguration" -Operation Evaluate;
}

function Provision-ServerConfiguration {
	param(
		[switch]$AllowReboot = $false, 
		[switch]$AllowSqlRestart = $false
	);

	Validate-MethodUsage -MethodName "Provision";
	Execute-Runbook -RunbookName "ServerConfiguration" -Operation Provision;
}
