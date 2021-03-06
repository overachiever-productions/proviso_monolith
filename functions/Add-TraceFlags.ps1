Set-StrictMode -Version 1.0;

function Add-TraceFlags {
	param ([string[]]$flags)
	
	foreach ($flag in $flags) {
		Add-TraceFlag $flag;
	}
}