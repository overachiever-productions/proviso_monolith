Set-StrictMode -Version 3.0;

function Find-MachineDefinition {
	param (
		[Parameter(Mandatory = $true)]
		[string]$RootDirectory,
		[Parameter(Mandatory = $true)]
		[string]$MachineName		
	);
	
	
	[string[]]$extensions = ".psd1", ".config", ".config.psd1";
	
	# search $RootDirectory for $MachineName+$Extension
	#  	 RECURSE ... 
	#     create a LIST of all matches i.e., location, filename (name.ext), and create-date + file-size. 
	
	#    output as [string[]]
	
	
}