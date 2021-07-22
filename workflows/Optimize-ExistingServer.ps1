<# 


	outline/flow: 
	1. Bootstrap Logic
	2. Determine Server Name + load definitions/resources. 

	3. Main Workflow:
		- Check disks
			report on allocation unit size
			report on use LargeFRS 
		- Enable DAC if not already done. 
			Enable DAC Firewall rule if windows Firewall is ON. 
		- Trace Flags	
		- User Rights Assignment
		- Deploy AdminDb
		- Walk through AdminDb setup (i.e., copy/paste from Configure-Server.ps1)
				or, hmm... maybe to avoid DRY.... maybe have that in some centralized script? 
#>


