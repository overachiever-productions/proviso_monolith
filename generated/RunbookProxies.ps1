Set-StrictMode -Version 1.0; 

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
		[switch]$AllowSqlRestart = $false, 
		[string]$NextRunbookOperation = $null
	);

	Validate-MethodUsage -MethodName "Provision";
	Execute-Runbook -RunbookName "ServerInitialization" -Operation Provision -AllowReboot:$AllowReboot -AllowSqlRestart:$AllowSqlRestart -NextRunbookOperation $NextRunbookOperation;
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
		[switch]$AllowSqlRestart = $false, 
		[string]$NextRunbookOperation = $null
	);

	Validate-MethodUsage -MethodName "Provision";
	Execute-Runbook -RunbookName "ServerConfiguration" -Operation Provision -AllowReboot:$AllowReboot -AllowSqlRestart:$AllowSqlRestart -NextRunbookOperation $NextRunbookOperation;
}															 

#-------------------------------------------------------------------------------------
# AdminDb
#-------------------------------------------------------------------------------------
function Evaluate-AdminDb {
	Validate-MethodUsage -MethodName "Evaluate";
	Execute-Runbook -RunbookName "AdminDb" -Operation Evaluate;
}

function Provision-AdminDb {
	param(
		[switch]$AllowReboot = $false, 
		[switch]$AllowSqlRestart = $false, 
		[string]$NextRunbookOperation = $null
	);

	Validate-MethodUsage -MethodName "Provision";
	Execute-Runbook -RunbookName "AdminDb" -Operation Provision -AllowReboot:$AllowReboot -AllowSqlRestart:$AllowSqlRestart -NextRunbookOperation $NextRunbookOperation;
}															 

#-------------------------------------------------------------------------------------
# ServerMonitoring
#-------------------------------------------------------------------------------------
function Evaluate-ServerMonitoring {
	Validate-MethodUsage -MethodName "Evaluate";
	Execute-Runbook -RunbookName "ServerMonitoring" -Operation Evaluate;
}

function Provision-ServerMonitoring {
	param(
		[switch]$AllowReboot = $false, 
		[switch]$AllowSqlRestart = $false, 
		[string]$NextRunbookOperation = $null
	);

	Validate-MethodUsage -MethodName "Provision";
	Execute-Runbook -RunbookName "ServerMonitoring" -Operation Provision -AllowReboot:$AllowReboot -AllowSqlRestart:$AllowSqlRestart -NextRunbookOperation $NextRunbookOperation;
}															 

#-------------------------------------------------------------------------------------
# Cluster
#-------------------------------------------------------------------------------------
function Evaluate-Cluster {
	Validate-MethodUsage -MethodName "Evaluate";
	Execute-Runbook -RunbookName "Cluster" -Operation Evaluate;
}

function Provision-Cluster {
	param(
		[switch]$AllowReboot = $false, 
		[switch]$AllowSqlRestart = $false, 
		[string]$NextRunbookOperation = $null
	);

	Validate-MethodUsage -MethodName "Provision";
	Execute-Runbook -RunbookName "Cluster" -Operation Provision -AllowReboot:$AllowReboot -AllowSqlRestart:$AllowSqlRestart -NextRunbookOperation $NextRunbookOperation;
}															 

#-------------------------------------------------------------------------------------
# AvailabilityGroups
#-------------------------------------------------------------------------------------
function Evaluate-AvailabilityGroups {
	Validate-MethodUsage -MethodName "Evaluate";
	Execute-Runbook -RunbookName "AvailabilityGroups" -Operation Evaluate;
}

function Provision-AvailabilityGroups {
	param(
		[switch]$AllowReboot = $false, 
		[switch]$AllowSqlRestart = $false, 
		[string]$NextRunbookOperation = $null
	);

	Validate-MethodUsage -MethodName "Provision";
	Execute-Runbook -RunbookName "AvailabilityGroups" -Operation Provision -AllowReboot:$AllowReboot -AllowSqlRestart:$AllowSqlRestart -NextRunbookOperation $NextRunbookOperation;
}															 

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
		[switch]$AllowSqlRestart = $false, 
		[string]$NextRunbookOperation = $null
	);

	Validate-MethodUsage -MethodName "Provision";
	Execute-Runbook -RunbookName "Tests" -Operation Provision -AllowReboot:$AllowReboot -AllowSqlRestart:$AllowSqlRestart -NextRunbookOperation $NextRunbookOperation;
}															 
