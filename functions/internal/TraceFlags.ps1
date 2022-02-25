Set-StrictMode -Version 1.0;

filter Add-TraceFlag {
	param (
		[Parameter(Mandatory)]
		$InstanceName,
		[Parameter(Mandatory)]
		[string]$Flag
	);
	
	$nextArgNameQuery = "WITH ordered AS ( 

        SELECT 
            CAST(REPLACE([value_name], N'SQLArg', N'') AS int) [ordinal],
            CAST(value_data AS sysname) value_data, 
            [registry_key]
        FROM 
            sys.[dm_server_registry] 
        WHERE 
            [registry_key] LIKE N'HKLM\Software\Microsoft\Microsoft SQL Server\%.%\MSSQLServer\Parameters'
            AND [value_name] LIKE 'SQLArg%'
    ) 

    SELECT TOP(1)
        REPLACE([registry_key], N'HKLM', N'HKLM:') [registry_key],
        'SQLArg' + (SELECT CAST((MAX([ordinal]) + 1) as sysname) FROM [ordered]) [next_arg_name]
    FROM 
        [ordered]; ";
	
	$nextArg = Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $InstanceName) -Query $nextArgNameQuery;
	
	$registryKey = $nextArg["registry_key"];
	$registryName = $nextArg["next_arg_name"];
	$registryValue = "-T$Flag";
	
	# add the key/value: 
	New-ItemProperty -Path $registryKey -Name $registryName -Value $registryValue -PropertyType STRING -Force | Out-Null;
	
	# and, enable the TF within global scope (i.e., until next Server/Service Restart).
	Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $InstanceName) -Query "DBCC TRACEON(`$(FLAG_VALUE), -1);" -Variable "FLAG_VALUE = $Flag";
}