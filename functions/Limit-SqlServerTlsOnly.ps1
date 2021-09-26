Set-StrictMode -Version 1.0;

function Limit-SqlServerTlsOnly {
	
	param (
		[string]$Instance = "MSSQLSERVER"
	);
	
	# grab the version key/path: 
	$path = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\').$Instance;
	
	$currentValue = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$path\MSSQLServer\SuperSocketNetLib\" -Name "ForceEncryption").ForceEncryption;
	if ($currentValue -ne 1) {
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$path\MSSQLServer\SuperSocketNetLib\" -Name "ForceEncryption" -Value 1;
	}
}