Set-StrictMode -Version 1.0;

Surface AdminDbDatabaseMail {
	
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	# TODO: add options that map to server.display_name, server.replyto_address, account.display_name, account.replyto_address
	Group-Definitions -GroupKey "AdminDb.*" {
		Definition "DatabaseMail Enabled" -ExpectValueForChildKey "DatabaseMail.Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				
				$mailXps = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT value_in_use [current] FROM sys.[configurations] WHERE [name] = N'Database Mail XPs'; ").current;
				if ($mailXps -eq 0) {
					return $false;
				}
				
				$profilesCount = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT COUNT(*) [count] FROM [msdb].dbo.[sysmail_profile]; ").count;
				if ($profilesCount -eq 0) {
					$PVContext.WriteLog("No Database Mail Profiles detected. Treating Database Mail as NON-CONFIGURED.", "Important");
					return $false;
				}
				
				return $true;
			}
			Configure {
				$instanceName = $PVContext.CurrentKeyValue;
				
				[string]$operatorEmail = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.OperatorEmail");
				[string]$smtpAccountName = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpAccountName");
				[string]$smtpOutAddy = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpOutgoingEmailAddress");
				[string]$smtpServer = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpServerName");
				[string]$portNumber = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpPortNumber");
				[string]$requiresSsl = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpRequiresSSL");
				[string]$authType = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpAuthType");
				[string]$userName = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmptUserName");
				[string]$password = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpPassword");
				[string]$sendEmail = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SendTestEmailUponCompletion");
				
				Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) -Query "EXEC admindb.dbo.[configure_database_mail]
					@OperatorEmail = N'$operatorEmail',
					@SmtpAccountName = N'$smtpAccountName',
					@SmtpOutgoingEmailAddress = N'$smtpOutAddy',
					@SmtpServerName = N'$smtpServer',
					@SmtpPortNumber = $portNumber, 
					@SmtpRequiresSSL = $requiresSsl, 
				    @SmptUserName = N'$userName',
				    @SmtpPassword = N'$password', 
					@SendTestEmailUponCompletion = $sendEmail ; ";
			}
		}
		
		Definition "SmtpAccountName" -ExpectValueForChildKey "DatabaseMail.SmtpAccountName" -ConfiguredBy "DatabaseMail Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$accountName = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [name] FROM msdb.dbo.[sysmail_account] WHERE [name] = N'$expectedSetting'; ").name;
				
				return $accountName;
			}
		}
		
		Definition "OperatorEmail" -ExpectValueForChildKey "DatabaseMail.OperatorEmail" -ConfiguredBy "DatabaseMail Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				# NOTE: this is hard-coded to check the email_address for the ALERTS operator.
				$emailAddress = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [email_address] FROM msdb.dbo.[sysoperators] WHERE [name] = 'Alerts' AND [email_address] = N'$expectedSetting'; ").email_address;
				
				return $emailAddress;
			}
		}
		
		Definition "SmtpServerName" -ExpectValueForChildKey "DatabaseMail.SmtpServerName" -ConfiguredBy "DatabaseMail Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$serverName = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [servername] [server] FROM msdb.dbo.[sysmail_server] WHERE [servername] = N'$expectedSetting'; ").server;
				
				return $serverName;
			}
		}
		
		Definition "OutgoingSmtpAddress" -ExpectValueForChildKey "DatabaseMail.SmtpOutgoingEmailAddress" -ConfiguredBy "DatabaseMail Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$accountName = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpAccountName");
				$outgoingAddress = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [email_address] FROM msdb.dbo.[sysmail_account] WHERE [name] = N'$accountName' AND [email_address] = N'$expectedSetting'; ").email_address;
				
				return $outgoingAddress;
			}
		}
		
		Definition "SmtpPortNumber" -ExpectValueForChildKey "DatabaseMail.SmtpPortNumber" -ConfiguredBy "DatabaseMail Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$accountName = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpAccountName");
				$port = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT s.[port] FROM msdb.dbo.[sysmail_server] s INNER JOIN [msdb].dbo.[sysmail_account] a ON [s].[account_id] = [a].[account_id] WHERE a.[name] = N'$accountName' AND s.[port] = $expectedSetting; ").port;
				
				return $port;
			}
		}
		
		Definition "RequireSSL" -ExpectValueForChildKey "DatabaseMail.SmtpRequiresSSL" -ConfiguredBy "DatabaseMail Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$accountName = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpAccountName");
				$ssl = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT s.[enable_ssl] FROM msdb.dbo.[sysmail_server] s INNER JOIN [msdb].dbo.[sysmail_account] a ON [s].[account_id] = [a].[account_id] WHERE a.[name] = N'$accountName'; ").enable_ssl;
				
				if ($ssl -eq 1) {
					return $true;
				}
				
				return $false;
			}
		}
		
		Definition "SmtpAuthType" -ExpectValueForChildKey "DatabaseMail.SmtpAuthType" -ConfiguredBy "DatabaseMail Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$accountName = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpAccountName");
				$authType = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT CASE WHEN s.[use_default_credentials] = 1 THEN N'WINDOWS' WHEN s.[use_default_credentials] = 0 AND s.[credential_id] IS NOT NULL THEN N'BASIC' ELSE N'ANONYMOUS'	END [auth_type] FROM msdb.dbo.[sysmail_server] s INNER JOIN [msdb].dbo.[sysmail_account] a ON [s].[account_id] = [a].[account_id] WHERE a.[name] = N'$accountName'; ").auth_type;
				
				return $authType;
			}
		}
		
		# TODO: account for scenarios where ... SmtpAuthType is WindowsAuth or Anonymous... 
		#   probably makes the most sense to implement an explicit Expect {} block to handle this... 
		#   as in: what 'username' we expect should depend upon the AUTH type - i.e., :
		#   	auth-type = anonymous then send <ANONYMOUS> out as the expect. 
		# 		auth-type = windows then ... <WINDOWS> ... 
		#       else, if auth-type = basic ... then "username"(from the config)
		Definition "SmptUserName" -ExpectValueForChildKey "DatabaseMail.SmptUserName" -ConfiguredBy "DatabaseMail Enabled" {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$accountName = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpAccountName");
				$username = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT s.[username] FROM msdb.dbo.[sysmail_server] s INNER JOIN [msdb].dbo.[sysmail_account] a ON [s].[account_id] = [a].[account_id] WHERE a.[name] = N'$accountName' AND s.[username] = N'$expectedSetting'; ").username;
				
				return $username;
			}
		}
	}
}