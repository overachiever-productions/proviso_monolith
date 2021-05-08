Set-StrictMode -Version 3.0;

function Add-TraceFlags {
	param ([string[]]$Flags)
	
	foreach ($flag in $Flags) {
		Add-TraceFlag $flag;
	}
}