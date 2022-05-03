Set-StrictMode -Version 1.0;

function Map {
	#[Alias("Add")]
	# Possible Alias: Configure
	
	param (
		[string]$ProvisoRoot,
		[switch]$RootFromRepoPath = $false
		# TODO: Proviso(User)Config
		# TODO: Proviso Options... 
	);
	
	begin {
		Validate-MethodUsage -MethodName "Map";
		
		$rootPath = $null;
		
		if ($ProvisoRoot) {
			if (-not (Test-Path $ProvisoRoot)) {
				throw "Invalid -ProvisoRoot value provided to [Map]. Path NOT found or does not exist.";
			}
		}
		elseif ($RootFromRepoPath) {
			$repo = Get-PSRepository | Where-Object -Property Name -Like '*proviso*';
			if ($repo -and ($repo.Count -eq 1)) {
				$repoPath = $repo.SourceLocation;
				
				if (Test-Path -Path $repoPath) {
					$rootPath = Split-Path -Path $repoPath -Parent;
					
					if (Test-Path -Path $rootPath) {
						$ProvisoRoot = $rootPath;
					}
				}
			}
			
		}
		else {
			#TODO: attempt to set from C:\Scripts or C:\Scripts\Proviso
			throw "Proviso Framework Error. -ProvisoRoot is CURRENTLY a required argument.";
		}
	};
	
	process {
		if ($ProvisoRoot) {
			$PVResources.SetRoot($ProvisoRoot);
			
			$definitionsPath = Join-Path -Path $ProvisoRoot -ChildPath "definitions";
			$PVCatalog.EnumerateHosts($definitionsPath);
			
			Register-ArgumentCompleter -CommandName "Target" -ParameterName "HostName" -ScriptBlock {
				$PVCatalog.GetEnumeratedHosts();
			};
		}
	};
	
	end {
		
	};
}