Set-StrictMode -Version 1.0;

function Configure-AdminDbDatabaseMail {
	
	Validate-MethodUsage -MethodName "Configure";

	Process-Surface -SurfaceName "AdminDbDatabaseMail" -Configure;
}