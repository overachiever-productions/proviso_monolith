Set-StrictMode -Version 1.0;

function Convert-SCSITargetIdToDeviceName {
	param (
		[Parameter(Mandatory = $true)]
		[int]$SCSITargetId
		# vNEXT: Account for SCSIPort in creation/definition of device details.
	);
	
	If ($SCSITargetId -eq 0) {
		return "/dev/sda1";
	}
	
	$deviceName = "xvd";
	If ($SCSITargetId -gt 25) {
		$deviceName += [char](0x60 + [int]($SCSITargetId / 26));
	}
	$deviceName += [char](0x61 + $SCSITargetId % 26);
	
	return $deviceName;
}