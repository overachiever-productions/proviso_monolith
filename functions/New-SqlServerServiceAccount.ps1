Set-StrictMode -Version 1.0;

#function New-DomainLevelServiceAccount {
function New-SqlServerServiceAccount {
	
	# TODO/NOTE: Everything in this 'function' is just a copy/paste of some working/INITIAL tests that I created and ran... 
	#     as in, REALLY, REALLY, need to weaponize this and so on. 
	
	
	# TODO: this _HAS_ to be run on the DC at this point... which is confusing/problematic... 
	#    I think the main reason for this is ... cuz $env:USERDOMAIN returns the 'machine-name' on boxes other than the DC. 
	#     Otherwise, if we COULD determine that we wanted to create AD users... then we'd need to collect DomainAdmin (or suitable) creds... 
	#        so. all of that said, it's ODD to have to go to the DC and create creds for SQL Server Services - in that it 'breaks' the SQL Server setup flow... BUT
	#          it's NOT that odd at ALL from a security standpoint ... 
	
	# this is how I ended up addressing Domain Name detection: $domain = (Get-WmiObject Win32_ComputerSystem).Domain.split(".")[0];
	
	# TODO: figure out why my attempt to account for users already existing is ... not working.
	
	$domain = $env:USERDOMAIN;
	$hostName = $env:COMPUTERNAME;
	$localPrincipal = $false;
	if ($domain -eq $hostName) {
		$localPrincipal = $true
	}
	
	$sqlServerServiceName = Read-Host -Prompt "UserName for _SQL SERVER_ Service";
	$sqlServerServicePassword = Read-Host -AsSecureString -Prompt "Password for _SQL SERVER_ Service";
	
	$sqlAgentServiceName = Read-Host -Prompt "UserName for SQL Server _AGENT_ Service";
	$sqlAgentServicePassword = Read-Host -AsSecureString -Prompt "Password for SQL Server _AGENT_ Service";
	
	# Note... It's dumb to create local accounts ... might just want to throw an error here instead... 
	if ($localPrincipal) {
		New-LocalUser -Name $sqlServerServiceName -Password $sqlServerServicePassword -UserMayNotChangePassword:$true -Disabled:$false -AccountNeverExpires:$true
		New-LocalUser -Name $sqlServerServiceName -Password $sqlServerServicePassword -UserMayNotChangePassword:$true -Disabled:$false -AccountNeverExpires:$true
		
	}
	else {
		
		$sqlServiceExists = Get-ADUser -Filter {
			Name -eq "$sqlServerServiceName"
		};
		$sqlAgentServiceExists = Get-ADUser -Filter {
			Name -eq "$sqlAgentServiceName"
		};
		
		if ($sqlServiceExists) {
			Write-Host "Account with name of $sqlServiceExists already exists.";
			#$overwriteSqlService = Read-Host "WARNING: Overwrite Password with Previously Specified Password? Y or N";
			#
			#if(($overwriteSqlService = 'Y') -or ($overwriteSqlService = 'y')) {
			#    Set-AdUser -Identity "$sqlServerServiceName" -Passw
			#}
			
		}
		else {
			New-ADUser -Name $sqlServerServiceName -AccountPassword $sqlServerServicePassword -CannotChangePassword:$true -Enabled:$true -PasswordNeverExpires:$true;
		}
		
		if ($sqlAgentServiceExists) {
			Write-Host "Account with name of $sqlAgentServiceExists already exists.";
			#$overwriteSqlServiceAgent = Read-Host "WARNING: Overwrite Password with Previously Specified Password? Y or N";
			#
			#if(($overwriteSqlServiceAgent = 'Y') -or ($overwriteSqlServiceAgent = 'y')) {
			#    
			#}
			
		}
		else {
			New-ADUser -Name $sqlAgentServiceName -AccountPassword $sqlAgentServicePassword -CannotChangePassword:$true -Enabled:$true -PasswordNeverExpires:$true;
		}
	}
	
}