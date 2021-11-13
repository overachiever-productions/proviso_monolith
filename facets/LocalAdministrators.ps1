Set-StrictMode -Version 1.0;

Facet "LocalAdministrators" -For -Key "Host.LocalAdministrators" {
	
	Assert -Is "Adminstrator" -FailureMessage "Current User is not a Member of the Administrators Group" {
		$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
		$admins = Get-LocalGroupMember -Group Administrators | Select-Object -Property "Name";
		
		if ($admins.Name -notcontains $currentUser) {
			return $false;
		}
	}
	
	Assert -Is "WindowsServer" {
		$os = (Get-ChildItem -Path Env:\POWERSHELL_DISTRIBUTION_CHANNEL).Value;
		if ($os -notlike "*Windows Server*") {
			return $true;
		}
	}
		
	Definitions {
		Definition "Local Admin Members" {
			Expect -That "Each entry listed in Config is a member of Local Admins" {
				$expectedAdmins = $PVConfig.GetValue("Host.LocalAdministrators");
				
				# so... i COULD serialize the array of outputs, e.g., "AWS\devops, AWS\mike" as the literal output. 
				# but, instead, I need to figure out how to do something along the lines of: 
				#  Expect -ForEachArrayKey "Host.LocalAdministrators"
				#    or maybe the definition is ... Definition -For -ArrayKey "Host.LocalAdministrators"
				#  		that's PROBABLY better...  yeah... then TEST and CONFIGURE each only have to account for a SINGLE input. 
				# 	
				#  implementation is a bit odd/weird though... well. it's CONFUSING. 
				#   
				#  For "Definition -For -ArrayKey 'Host.LocalAdmins' "
				#   	there are ROUGHLY 2x options... for implementation: 
				#      a. during the building/creation/definition process... 
				#         I spin up N {definitions} of the same 'definition'
				#  				i.e., assume that there are 2x entries in Host.localAdmins (AWS\devops, AWS\mike)
				#  			then, I'd have a definition for "Local Admin Members - AWS\devops" and "Local Admin Members - AWS\mike". 
				#  				where each would have the EXPECT block for the code in question as "aws\devops" and "aws\mike" respectively. 
				#  			or, in other words, a definition with -ArrayKey is a helper-method/shortcut in that it creates N rules (definitions) - 1x per each entry. 
				# 			this actually works QUITE well. 
				# 				with one caveat - which is that I don't THINK i want the FULL-blown 'formatting overhead' of Nx definitions (one per array entry)
				# 					when spitting out the validation summary and/or config-summary. 
				# 				SO... IF I go this route (and probably will) ... I need some sort of definition 'flag'/property that basically says: 
				# 					hey, i'm a sub-rule and my 'parent' would be "Host.LocalAdministrators" - or wahtever. 
				
				# 			well... shit. as fun as the stuff above is... 
				# 				there's a slight issue: i can't create N 'funcs' (definitions) at 'create time'... cuz... i don't have the actual .config file yet
				# 				and don't know how many Ns there will be.. 
				# 					still, though, something that could/would replace or 'rewrite' the defs MIGHT be the way to go? 
				# 						i.e., if "ForArrayKey" then ... dynamically re-create the def at run time when processing a .config key? 					
				
				
				#     	b. instead of creating N rules during 'creation time'
				# 			use, roughly the same idea... 
				# 				but everything has to be done INSIDE of a single 'func'/definition. 
				# 				NOT too terribly hard - but... this'd mean that a func/definition would NOT be the 'lowest' level to report ... 
				# 					validation summary and config-outcomes/summary data into - there'd be a 'child' or lower level. 
				
				
				#    		arguably, option 2 almost makes more sense? 
				
				# TODO: revisit how I want outputs/summary data from facet processing to 'look'... and then figure out which of the above approaches
				# 		PROBABLY makes the most sense given the above. 
				# 			that said, option a. looks to be the EASIEST overall. 
				# 			it's basically a 'tweak' to existing functionalilty - i.e., instead of adding 1x 'scalar' 'func/definition', I add (or back-post/re-write)
				# 				Nx 'scalar' funcs/defs dynamically... 
				
				
				# Finally... the above gets me that much closer to being able to handle things like: 
				# 	ExpectedShares - they're just a TINY bit more complex than "for N admins" - as in, they're multiple properties/values per each 'loop' or iteration. 
				#   ExpectedDirectories - ditto with the above. 
				#   EthernetAdapters - again, just multiple-ish properties. 
				#  	  ... then, getting more complex:
				#  	ExpectedDisks ... yeah, these are COMPLEX AF... but, 'each' is just a 'rule'... with a) lots of properties and b) COMPLEX state. 
				#     ... finally: 
				# 	SQL Installs, SQL Configs, and anything else that can/will be scoped by an {INSTANCE}
				# 		basically, they're just 'really complex disks or nics' in terms of complexity and scope/state. 
				# 			moreover, if i 'write' the code for MSSQLSERVER as an 'option' (plugable variable or whatever)
				# 			then... the ONLY thing that'd change for, say, a named instance... would be the name and so on... 
				
				# with all of the above in mind: 
				#   Definition [-For] -ArrayKey is... decently-ish named. I can probably do a bit better (-ForEachKeyValue -In "key.name.here", -xxx? -whatever)
				#   and... 
				#    i think i want something slightly different for each 'component' that gets configured/installed this way. 
				# 		e.g., Definition -ForEachComponentKey -In "Host.ExpectedDisks"
				
				
			}
			
			Test {
				# foreach ... $expectedAdmin in $expectedAdmins... is it a member of admins? 
				# and... keep tabs/create test OUTPUTs/results for EACH entry. 
				return $false;
			}
			
			Configure {
				# foreach expected that is NOT a current member... ADD. 
				#   and ... keep tabs on EACH outcome/processing thingy. 
				Write-Host "Not implemented yet...";
			}
		}
	}
}