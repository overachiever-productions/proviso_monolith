Set-StrictMode -Version 1.0;

function Limit-SqlServerTlsOnly {
	param (
		
	);
	
	
	$currentValue = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQLServer\SuperSocketNetLib\" -Name "ForceEncryption").ForceEncryption;
	
	if ($currentValue -ne 1) {
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQLServer\SuperSocketNetLib\" -Name "ForceEncryption" -Value 1;
	}
}