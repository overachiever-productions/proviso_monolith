Set-StrictMode -Version 1.0;

# Tasks: 
#  1. Disable via Registry: 
#  2. Set "SQL Server CEIP service (MSSQLSERVER)" to Manual/Disabled + Stop. 
#  3. Drop the XE Session.


filter Disable-TelemetryXEventsTrace {
	
	param (
		[string]$InstanceName = "MSSQLSERVER",
		[int]$MajorVersion = 15,
		# SQL Server 2019. vNext: Replace this with a new SqlServerVersion type...
		[string]$CEIPServiceStartup = "Manual" # could be Disabled too... 
	);
	
	# Disable CEIP options via registry:	
	# TODO: MIGHT make sense to fetch these via [sys].[xp_instance_regread] - i.e., similar to how the paths for TraceFlags are retrieved in Add-TraceFlag (internal)
	
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL$($MajorVersion).MSSQLSERVER\CPE\" -Name "CustomerFeedback" -Value 0 | Out-Null;
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL$($MajorVersion).MSSQLSERVER\CPE\" -Name "EnableErrorReporting" -Value 0 | Out-Null;
	
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($MajorVersion)0" -Name "CustomerFeedback" -Value 0 | Out-Null;
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($MajorVersion)0" -Name "EnableErrorReporting" -Value 0 | Out-Null;
	
	Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server\$($MajorVersion)0" -Name "CustomerFeedback" -Value 0 | Out-Null;
	Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server\$($MajorVersion)0" -Name "EnableErrorReporting" -Value 0 | Out-Null;
	
	# Disable Auto-Start on Service + Stop Service.
	Set-Service -Name "SQLTELEMETRY" -StartupType $CEIPServiceStartup;
	
	$service = Get-Service "SQLTELEMETRY";
	
	# -- vNEXT: DRY-violation here... push this into Wait-UntilServiceStatus as a call/etc. 
	if ($service.Status -ne "Stopped") {
		try {
			Stop-Service $service -Force;
			$service.WaitForStatus("Stopped", '00:00:30');
		}
		catch [System.ServiceProcess.TimeoutException] {
			throw "Timeout Exception Encountered - SQLTELEMETRY Service NOT stop within 30 seconds.";
		}
		catch {
			throw "Unexpected Problem Encountered: " + $PSItem.Exception.Message;
		}
	}
	
	Invoke-SqlCmd -Query "IF EXISTS (SELECT NULL FROM sys.[server_event_sessions] WHERE [name] = N'telemetry_xevents')
			DROP EVENT SESSION [telemetry_xevents] ON SERVER;
		GO" -DisableVariables;
}