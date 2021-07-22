Set-StrictMode -Version 1.0;

function Get-ConfigValue {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$Definition,
		[Parameter(Mandatory = $true)]
		[string]$Key,
		$Default
	);
	
	begin {
		# vNEXT: figure out a way to verify that $ServerDefinition is a) a thing and b) a correctly-formed definition set/file/whatever. 
	};
	
	process {
		
		$keys = $Key -split "\.";
		
		# vNEXT: There has to be a better way to do this... but, for now, I don't care... 
		$out = $null;
		switch($keys.Count) {
			1 {
				$out = $Definition.($keys[0]);
			}
			2 {
				$out = $Definition.($keys[0]).($keys[1]);
			}
			3 {
				$out = $Definition.($keys[0]).($keys[1]).($keys[2]);
			}
			4 {
				$out = $Definition.($keys[0]).($keys[1]).($keys[2]).($keys[3]);
			}
		}
		
		if ((($out -eq $null) -or ([string]::IsNullOrEmpty($out))) -and (($Default -ne $null) -or (-not([string]::IsNullOrEmpty($Default))))) {
			$out = $Default;
		}
		
		return $out;
	};
	
	end {
		
	};
}