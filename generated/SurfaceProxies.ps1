Set-StrictMode -Version 1.0; 

#-------------------------------------------------------------------------------------
# AdminDb
#-------------------------------------------------------------------------------------
function Validate-AdminDb {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "AdminDb";
}

function Configure-AdminDb {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "AdminDb" -Operation "Configure";
}

function Run-AdminDb {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "AdminDb" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# AdminDbAlerts
#-------------------------------------------------------------------------------------
function Validate-AdminDbAlerts {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "AdminDbAlerts";
}

function Configure-AdminDbAlerts {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "AdminDbAlerts" -Operation "Configure";
}

function Run-AdminDbAlerts {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "AdminDbAlerts" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# AdminDbBackups
#-------------------------------------------------------------------------------------
function Validate-AdminDbBackups {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "AdminDbBackups";
}

function Configure-AdminDbBackups {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "AdminDbBackups" -Operation "Configure";
}

function Run-AdminDbBackups {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "AdminDbBackups" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# AdminDbConsistencyChecks
#-------------------------------------------------------------------------------------
function Validate-AdminDbConsistencyChecks {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "AdminDbConsistencyChecks";
}

function Configure-AdminDbConsistencyChecks {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "AdminDbConsistencyChecks" -Operation "Configure";
}

function Run-AdminDbConsistencyChecks {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "AdminDbConsistencyChecks" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# AdminDbDatabaseMail
#-------------------------------------------------------------------------------------
function Validate-AdminDbDatabaseMail {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "AdminDbDatabaseMail";
}

function Configure-AdminDbDatabaseMail {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "AdminDbDatabaseMail" -Operation "Configure";
}

function Run-AdminDbDatabaseMail {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "AdminDbDatabaseMail" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# AdminDbDiskMonitoring
#-------------------------------------------------------------------------------------
function Validate-AdminDbDiskMonitoring {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "AdminDbDiskMonitoring";
}

function Configure-AdminDbDiskMonitoring {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "AdminDbDiskMonitoring" -Operation "Configure";
}

function Run-AdminDbDiskMonitoring {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "AdminDbDiskMonitoring" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# AdminDbHistory
#-------------------------------------------------------------------------------------
function Validate-AdminDbHistory {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "AdminDbHistory";
}

function Configure-AdminDbHistory {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "AdminDbHistory" -Operation "Configure";
}

function Run-AdminDbHistory {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "AdminDbHistory" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# AdminDbIndexMaintenance
#-------------------------------------------------------------------------------------
function Validate-AdminDbIndexMaintenance {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "AdminDbIndexMaintenance";
}

function Configure-AdminDbIndexMaintenance {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "AdminDbIndexMaintenance" -Operation "Configure";
}

function Run-AdminDbIndexMaintenance {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "AdminDbIndexMaintenance" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# AdminDbInstanceSettings
#-------------------------------------------------------------------------------------
function Validate-AdminDbInstanceSettings {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "AdminDbInstanceSettings";
}

function Configure-AdminDbInstanceSettings {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "AdminDbInstanceSettings" -Operation "Configure";
}

function Run-AdminDbInstanceSettings {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "AdminDbInstanceSettings" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# AdminDbRestoreTests
#-------------------------------------------------------------------------------------
function Validate-AdminDbRestoreTests {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "AdminDbRestoreTests";
}

function Configure-AdminDbRestoreTests {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "AdminDbRestoreTests" -Operation "Configure";
}

function Run-AdminDbRestoreTests {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "AdminDbRestoreTests" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# DataCollectorSets
#-------------------------------------------------------------------------------------
function Validate-DataCollectorSets {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "DataCollectorSets";
}

function Configure-DataCollectorSets {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "DataCollectorSets" -Operation "Configure";
}

function Run-DataCollectorSets {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "DataCollectorSets" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# ExpectedDirectories
#-------------------------------------------------------------------------------------
function Validate-ExpectedDirectories {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "ExpectedDirectories";
}

function Configure-ExpectedDirectories {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "ExpectedDirectories" -Operation "Configure";
}

function Run-ExpectedDirectories {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "ExpectedDirectories" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# ExpectedDisks
#-------------------------------------------------------------------------------------
function Validate-ExpectedDisks {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "ExpectedDisks";
}

function Configure-ExpectedDisks {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "ExpectedDisks" -Operation "Configure";
}

function Run-ExpectedDisks {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "ExpectedDisks" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# ExpectedShares
#-------------------------------------------------------------------------------------
function Validate-ExpectedShares {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "ExpectedShares";
}

function Configure-ExpectedShares {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "ExpectedShares" -Operation "Configure";
}

function Run-ExpectedShares {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "ExpectedShares" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# ExtendedEvents
#-------------------------------------------------------------------------------------
function Validate-ExtendedEvents {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "ExtendedEvents";
}

function Configure-ExtendedEvents {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "ExtendedEvents" -Operation "Configure";
}

function Run-ExtendedEvents {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "ExtendedEvents" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# FirewallRules
#-------------------------------------------------------------------------------------
function Validate-FirewallRules {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "FirewallRules";
}

function Configure-FirewallRules {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "FirewallRules" -Operation "Configure";
}

function Run-FirewallRules {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "FirewallRules" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# HostTls
#-------------------------------------------------------------------------------------
function Validate-HostTls {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "HostTls";
}

function Configure-HostTls {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "HostTls" -Operation "Configure";
}

function Run-HostTls {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "HostTls" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# LocalAdministrators
#-------------------------------------------------------------------------------------
function Validate-LocalAdministrators {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "LocalAdministrators";
}

function Configure-LocalAdministrators {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "LocalAdministrators" -Operation "Configure";
}

function Run-LocalAdministrators {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "LocalAdministrators" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# NetworkAdapters
#-------------------------------------------------------------------------------------
function Validate-NetworkAdapters {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "NetworkAdapters";
}

function Configure-NetworkAdapters {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "NetworkAdapters" -Operation "Configure";
}

function Run-NetworkAdapters {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "NetworkAdapters" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# RequiredPackages
#-------------------------------------------------------------------------------------
function Validate-RequiredPackages {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "RequiredPackages";
}

function Configure-RequiredPackages {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "RequiredPackages" -Operation "Configure";
}

function Run-RequiredPackages {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "RequiredPackages" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# ServerName
#-------------------------------------------------------------------------------------
function Validate-ServerName {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "ServerName";
}

function Configure-ServerName {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "ServerName" -Operation "Configure";
}

function Run-ServerName {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "ServerName" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# SqlConfiguration
#-------------------------------------------------------------------------------------
function Validate-SqlConfiguration {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "SqlConfiguration";
}

function Configure-SqlConfiguration {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "SqlConfiguration" -Operation "Configure";
}

function Run-SqlConfiguration {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "SqlConfiguration" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# SqlInstallation
#-------------------------------------------------------------------------------------
function Validate-SqlInstallation {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "SqlInstallation";
}

function Configure-SqlInstallation {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "SqlInstallation" -Operation "Configure";
}

function Run-SqlInstallation {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "SqlInstallation" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# Ssms
#-------------------------------------------------------------------------------------
function Validate-Ssms {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "Ssms";
}

function Configure-Ssms {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "Ssms" -Operation "Configure";
}

function Run-Ssms {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "Ssms" -Operation $operationType;
}

#-------------------------------------------------------------------------------------
# TestingSurface
#-------------------------------------------------------------------------------------
function Validate-TestingSurface {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "TestingSurface";
}

function Configure-TestingSurface {	param(		[switch]$ExecuteRebase = $false, 		[Switch]$Force = $false	); 
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "TestingSurface" -Operation "Configure" -ExecuteRebase:$ExecuteRebase -Force:$Force ;
}

function Run-TestingSurface {	param(		[switch]$ExecuteRebase = $false, 		[Switch]$Force = $false	); 
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "TestingSurface" -Operation $operationType -ExecuteRebase:$ExecuteRebase -Force:$Force ;
}

#-------------------------------------------------------------------------------------
# WindowsPreferences
#-------------------------------------------------------------------------------------
function Validate-WindowsPreferences {
	Validate-MethodUsage -MethodName "Validate";
	Process-Surface -SurfaceName "WindowsPreferences";
}

function Configure-WindowsPreferences {
	Validate-MethodUsage -MethodName "Configure";
	Process-Surface -SurfaceName "WindowsPreferences" -Operation "Configure";
}

function Run-WindowsPreferences {
	Validate-MethodUsage -MethodName "Run";
	Validate-RunbookProcessing;
	$operationType = $PVContext.GetSurfaceOperationFromCurrentRunbook();
	
	Process-Surface -SurfaceName "WindowsPreferences" -Operation $operationType;
}
