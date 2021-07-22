Set-StrictMode -Version 1.0;

function Add-TraceFlags {
	param ([string[]]$Flags)
	
	foreach ($flag in $Flags) {
		Add-TraceFlag -Flag $flag;
	}
}