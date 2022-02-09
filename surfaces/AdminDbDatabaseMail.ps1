Set-StrictMode -Version 1.0;

Surface AdminDbDatabaseMail {
	
	Assertions {
		Assert-SqlServerIsInstalled;
		Assert-AdminDbInstalled;
	}
	
	
	Aspect -Scope "AdminDb.*" {
		Facet "DatabaseMail Enabled" -ExpectChildKeyValue "DatabaseMail.Enabled" -UsesBuild {
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
		}
		
		Facet "SmtpAccountName" -ExpectChildKeyValue "DatabaseMail.SmtpAccountName" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$accountName = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [name] FROM msdb.dbo.[sysmail_account] WHERE [name] = N'$expectedSetting'; ").name;
				
				return $accountName;
			}
		}
		
		Facet "OperatorEmail" -ExpectChildKeyValue "DatabaseMail.OperatorEmail" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				# NOTE: this is hard-coded to check the email_address for the ALERTS operator.
				$emailAddress = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [email_address] FROM msdb.dbo.[sysoperators] WHERE [name] = 'Alerts' AND [email_address] = N'$expectedSetting'; ").email_address;
				
				return $emailAddress;
			}
		}
		
		Facet "SmtpServerName" -ExpectChildKeyValue "DatabaseMail.SmtpServerName" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$serverName = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [servername] [server] FROM msdb.dbo.[sysmail_server] WHERE [servername] = N'$expectedSetting'; ").server;
				
				return $serverName;
			}
		}
		
		Facet "OutgoingSmtpAddress" -ExpectChildKeyValue "DatabaseMail.SmtpOutgoingEmailAddress" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$accountName = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpAccountName");
				$outgoingAddress = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT [email_address] FROM msdb.dbo.[sysmail_account] WHERE [name] = N'$accountName' AND [email_address] = N'$expectedSetting'; ").email_address;
				
				return $outgoingAddress;
			}
		}
		
		Facet "SmtpPortNumber" -ExpectChildKeyValue "DatabaseMail.SmtpPortNumber" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$accountName = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpAccountName");
				$port = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT s.[port] FROM msdb.dbo.[sysmail_server] s INNER JOIN [msdb].dbo.[sysmail_account] a ON [s].[account_id] = [a].[account_id] WHERE a.[name] = N'$accountName' AND s.[port] = $expectedSetting; ").port;
				
				return $port;
			}
		}
		
		Facet "RequireSSL" -ExpectChildKeyValue "DatabaseMail.SmtpRequiresSSL" -UsesBuild {
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
		
		Facet "SmtpAuthType" -ExpectChildKeyValue "DatabaseMail.SmtpAuthType" -UsesBuild {
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$accountName = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpAccountName");
				$authType = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT CASE WHEN s.[use_default_credentials] = 1 THEN N'WINDOWS' WHEN s.[use_default_credentials] = 0 AND s.[credential_id] IS NOT NULL THEN N'BASIC' ELSE N'ANONYMOUS'	END [auth_type] FROM msdb.dbo.[sysmail_server] s INNER JOIN [msdb].dbo.[sysmail_account] a ON [s].[account_id] = [a].[account_id] WHERE a.[name] = N'$accountName'; ").auth_type;
				
				return $authType;
			}
		}
		
		
		Facet "SmptUserName" -ExpectChildKeyValue "DatabaseMail.SmptUserName" -UsesBuild {
			# TODO: account for scenarios where ... SmtpAuthType is WindowsAuth or Anonymous... 
			#   probably makes the most sense to implement an explicit Expect {} block to handle this... 
			#   as in: what 'username' we expect should depend upon the AUTH type - i.e., :
			#   	auth-type = anonymous then send <ANONYMOUS> out as the expect. 
			# 		auth-type = windows then ... <WINDOWS> ... 
			#       else, if auth-type = basic ... then "username"(from the config)			
			Test {
				$instanceName = $PVContext.CurrentKeyValue;
				$expectedSetting = $PVContext.CurrentChildKeyValue;
				
				$accountName = $PVConfig.GetValue("AdminDb.$instanceName.DatabaseMail.SmtpAccountName");
				$username = (Invoke-SqlCmd -ServerInstance (Get-ConnectionInstance $instanceName) "SELECT s.[username] FROM msdb.dbo.[sysmail_server] s INNER JOIN [msdb].dbo.[sysmail_account] a ON [s].[account_id] = [a].[account_id] WHERE a.[name] = N'$accountName' AND s.[username] = N'$expectedSetting'; ").username;
				
				return $username;
			}
		}
		
		# TODO: add options that map to server.display_name, server.replyto_address, account.display_name, account.replyto_address
		
		Build {
			$sqlServerInstance = $PVContext.CurrentKeyValue;
			$facetName = $PVContext.CurrentFacetName;
			$matched = $PVContext.Matched;
			$expected = $PVContext.Expected;
			
			if ($false -eq $expected) {
				switch ($facetName) {
					"DatabaseMail Enabled" {
						$PVContext.WriteLog("Config setting for [Admindb.$sqlServerInstance.DatabaseMail.Enabled] is set to `$false - but Database Mail has already been configured. Proviso will NOT tear-down Database Mail. Please make changes manually.", "Critical");
						return; # i.e., don't LOAD current instance-name as a name that needs to be configured (all'z that'd do would be to re-run SETUP... not tear-down.);
					}
				}
			}
			
			if (-not ($matched)) {
				$currentInstances = $PVContext.GetSurfaceState("TargetInstances");
				if ($null -eq $currentInstances) {
					$currentInstances = @();
				}
				
				if ($currentInstances -notcontains $sqlServerInstance) {
					$currentInstances += $sqlServerInstance
				}
				
				$PVContext.SetSurfaceState("TargetInstances", $currentInstances);
			}
		}
		
		Deploy {
			$currentInstances = $PVContext.GetSurfaceState("TargetInstances");
			
			foreach ($instanceName in $currentInstances) {
				
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
	}
}