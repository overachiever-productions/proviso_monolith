Set-StrictMode -Version 1.0;

function Validate-Config {
	
	if ($null -eq $PVConfig) {
		throw "Invalid Operation. `$PVConfig has not been set yet - or is `$null. Please ensure that [With] has been executed to defined a configuration block for processing needs.";
	}
	else {
		$methodsSet = $PVConfig.MembersConfigured;
		if (($null -eq $methodsSet) -or (-not ($methodsSet))) {
			throw "Invalid Operation. `$PVConfig has not been properly initialized. Please exeucte [With] before processing.";
		}
	}
}