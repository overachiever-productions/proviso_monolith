# Proviso

> ### :label: **NOTE:** 
> This documentation is a work in progress. Any content [surrounded by square brackets] represents a DRAFT version of documentation.






## Authoring Facets


### Definitions

#### Standard Definitions
##### Explicit Expect{} Blocks
It typically makes the most sense to return a `$true` | `$false` value from `Expect` blocks: 
```powershell

Definition "TheValueOfTrueIs$True" {
    Expect {
        return $true; # or... false... 
    }
    Test {...} 
    Configure{...}
}

```
But, you can also output strings or other values. Just make sure that the `Test` block returns data of the same, underlying, type: 
```powershell

Definition "ItIsTuesday" {
    Expect {
        return "Tuesday"; #NOTE: strictly speaking, return is not needed here. "Tuesday" would work
    }
    Test {
        return [System.DateTime]::Now.DayOfWeek.ToString();
    } 
    Configure{...}
}

```

##### Using the -Expect Parameter
For simple expecations, using the `-Expect` parameter as part of your definition can make definitions a lot easier to write than using explicit `Expect` blocks: 
```powershell

Definition "TheValueOfTrueIs$True" -Expect $true {
    # There is NO Expect{} block; and, when -Expect is used, Expect{} is not allowed...
    Test {...} 
    Configure{...}
}

```

And, of course, the `-Expect` parameter allows values other than merely true or false: 

```powershell

Definition "ItIsTuesday" -Expect "Tuesday" {
    # There is NO Expect{} block; and, when -Expect is used, Expect{} is not allowed...
    Test {
        return [System.DateTime]::Now.DayOfWeek.ToString();
    } 
    Configure{...}
}

```

##### Using a Configuration -Key value
Rather than using `Expect{}` code blocks or the `-Expect` parameter, `Definition` blocks also allow for the use of Proviso Configuration Keys. 

For example, the following code snippet will use the a machine's configuration file (or Proviso defaults if an explicit value for the key indicated is NOT defined in a .psd1 file) to determine whether the expectation for a firewall rule for SQL Server is enabled or not:

```powershell

Definition "SQL Server" -ExpectKeyValue "Host.FirewallRules.EnableFirewallForSqlServer" {
	Test {...} # i.e., figure out if the firewall rule in question is enabled ($true or $false)
	Configure {...} # set the firewall rule if/as needed... 
}

```


#### Value Definitions
Value-Definitions are `Definition`s that are defined within a `Value-Definitions` block. 
They allow for iteration over an ARRAY (not Hashtable) of results found at at given configuration Key.

Assume the following configuration (i.e., dev-ops and dbas SHOULD be members of the local (Windows) administrators group).

```powershell

@{
    Host = @{
        LocalAdministrators = @(
            "OA\dev-ops"
            "OA\dbas"
        )
    }
}

```

Using the configuration above, the most obvious implementation (to check that each of the values within the config for Host.LocalAdministrators) is a member of the Local Admins group would be to simply 'force' a simple `$true` value as output, like so: 

```powershell

Value-Definitions -ValueKey "Host.LocalAdministrators" {
    Definition "IsMemberOfLocalAdmins" -Expect $true {
        Test {...} # code to determine if <currentArrayValue> is a member of local admins.
        Configure{...} # code to put <currentArrayValue> into local admins (if needed).
    }
}

```

It is, however, also possible to create explicit `Expect{}` blocks - that can use the current value of the Array being iterated over - via the built-in `$PVContext.CurrentKeyValue` parameter to do more explicit checks if/as needed: 

```powershell

# assume config values similar to the following: 
@{
    Scripts = @{
        PostConfiguration = @(
            "C:\scripts\post-config\file1.sql"
            "C:\scripts\post-config\file2.sql"
            "C:\scripts\post-config\file3.sql"
        )
    }
}

Value-Definitions -ValueKey "Scripts.PostConfiguration" {
    Definition "IsMemberOfLocalAdmins" {
        Expect {
            # assume that, for whatever reason, file2.sql doesn't exist in the targetted folder: 
            return Test-Path ($PVContext.CurrentKeyValue);
            #  if the file exists, code could/would/should expect to run the file in question
            #    whereas, if it doesn't, expect a $false as the Expect value. 
        }
        Test {...} # arguably, should probably run the 'expect' logic from above here... 
        Configure{...} # for every $true result for Test-Path in Expect, run the file in question.
    }
}

```

#### Group Definitions
Group-Definitions are blocks or 'groups' of `Definitions` defined within a `Group-Definitions` block. They allow for iteration over entire blocks (or groups) of Hashtable values found at the location specified by a given configuration key. 

For example, 0 - N Data Collector Sets can be deployed/managed by means of the `DataCollectorSets` configuration node - as demonstrated below: 

```powershell

	DataCollectorSets  = @{
		
		Consolidated = @{
			Enabled			      = $true
			XmlDefinition		  = "" # if NOT explicitly specified will be <GroupName>.xml - e.g., Consolidated.xml
			EnableStartWithOS	  = $true
			DaysWorthOfLogsToKeep = "45" # if empty then NO cleanup... 
		}
		
		Mirroring = @{
			Enabled = $true
			XmlDefinition		  = ""
			EnableStartWithOS	  = $true
			DaysWorthOfLogsToKeep = "20"
		}
		
		YetAnotherDataSetNameHere = @{
			Enabled = $false
		}
	}

```

In the configuration example above, there are/would-be 3x different Data Collector sets to manage - "Consolidated", "Mirroring", and "YetAnotherDataSetNameHere" - where the first two Data Collector Sets SHOULD be enabled and configured and the third should not. 

Within a `Group-Definition` block, you can target dynamic configuration entries/values - such as "Consolidated", "Mirroring", "etc" (on up to N entries) by means of specifying a `-GroupKey` - which'll grab ALL 'groups' underneath a given config-node - along with an `Expect` in the form of an `-ExpectChildKey` path as well: 

```powershell 

Group-Definitions -GroupKey "DataCollectorSets.*" {
    Definition "IsCollectorSetEnabled" -ExpectChildKey "Enabled" {
        Test {
            # for each * in DataCollectorSets (i.e., for "Consolidated", "Mirroring", "etc.")
            #  the expect will have defined $true, $true, $false for the 3x values in the 
            #       config sample defined above
            
            # with that in mind, the following code would report whether collector-sets with 
            #   the names in question are enabled or not: 
            $status = Get-DataCollectoStatus $($PVContext.CurrentKeyGroup); # Consolidated, Mirroring, etc... 
            
            if($status -eq "NotFound") {
                return $false;
            }
            
            return ($status -eq "Running");
        }
        Configure {
            # code here would do what's needed to enable/disable each DataCollectorSet (by Group-key)
            #   as needed ... 
        }
    }
}