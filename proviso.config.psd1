@{
	ResourcesRoot = "\\storage\Lab\Proviso"
	
	# entirely optional... i.e., entire node is optional... 
	Preferences = @{
		LoggingLevel = "Info | Verbose | Debug | Whatever... "
	}
	
	Overrides	  = @{
		# Not implemented until v0.9+ or later... 
		# i.e., the following can/will ALLOW FOR optional overrides of specific directories and/or settings... 
		RepositoryName = "Name of Existing/Pre-registered PS Repository";
		DefinitionsRoot = "Alternate/Overrid path to ... Definitions"
		BinariesRoot = "Alternate/Overrid path to ... Binaries"
		AssetsRoot = "Alternate/Overrid path to ... Assets"
		WorkflowsRoot = "Alternate/Overrid path to ... Workflows"
		EtcRoot = "Alternate/Overrid path to ... etc"
	}
}