Set-StrictMode -Version 1.0;

# This is, effectively, an internal facade... 
filter Get-ProvisoFacetManager {
	
	if ($null -eq $script:provisoFacetManager){
		$script:provisoFacetManager = [Proviso.Models.FacetManager]::Instance
	}
	return $script:provisoFacetManager;
}