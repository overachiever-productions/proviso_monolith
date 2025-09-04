Set-StrictMode -Version 1.0;

# PREMISE: these can/should stay in Provio (they're just 'bridging' methods... )

filter Translate-AdminDbVectorFromDays {
	param (
		[Parameter(Mandatory)]
		[int]$Days,
		[Parameter(Mandatory)]
		[string]$ComparisonVectorFormat
	);
	
	switch ($ComparisonVectorFormat) {
		{ $_ -like '*day*' } {
			return Pluralize-Vector -Unit $Days -UnitType "day";
		}
		{ $_ -like '*week*'	} {
			return Pluralize-Vector -Unit ([int]($Days / 7)) -UnitType "week";
		}
		{ $_ -like '*month*' } {
			return Pluralize-Vector -Unit ([int]($Days / 30)) -UnitType "month";
		}
		{ $_ -like '*year*'	} {
			return Pluralize-Vector -Unit ([int]($Days / 365)) -UnitType "year";
		}
	}
	
	throw "Proviso Framwork Error. Unexpected Target Format for Output of Vector";
}

filter Pluralize-Vector {
	param (
		[Parameter(Mandatory)]
		$Unit,
		[Parameter(Mandatory)]
		[string]$UnitType
	);
	
	if ($Unit -lt 1) {
		$Unit = "~0";
	}
	
	if ($Unit -ne 1) {
		$UnitType = $UnitType + "s";
	}
	
	return "$Unit $UnitType";
}