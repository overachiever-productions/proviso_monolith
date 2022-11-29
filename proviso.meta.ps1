Set-StrictMode -Version 1.0;

function Import-ProvisoTypes {
	param (
		[string]$ScriptRoot = $PSScriptRoot
	);
	
	$classFiles = @(
		# manually-ish ordered/arranged to address dependency chains:
		"$ScriptRoot\clr\Proviso.Models\Enums\AssertionsOutcome.cs"
		"$ScriptRoot\clr\Proviso.Models\Enums\ConfigurationsOutcome.cs"
		"$ScriptRoot\clr\Proviso.Models\Enums\FacetType.cs"
		"$ScriptRoot\clr\Proviso.Models\Enums\CredentialsType.cs"
		"$ScriptRoot\clr\Proviso.Models\Enums\SurfaceProcessingState.cs"
		"$ScriptRoot\clr\Proviso.Models\Enums\RebaseOutcome.cs"
		"$ScriptRoot\clr\Proviso.Models\Enums\ValidationErrorType.cs"
		"$ScriptRoot\clr\Proviso.Models\Enums\ValidationsOutcome.cs"
		"$ScriptRoot\clr\Proviso.Models\Enums\ConfigEntryDataType.cs"
		"$ScriptRoot\clr\Proviso.Models\Enums\SqlInstanceKeyType.cs"
		"$ScriptRoot\clr\Proviso.Models\Models\Assertion.cs"
		"$ScriptRoot\clr\Proviso.Models\Models\Facet.cs"
		"$ScriptRoot\clr\Proviso.Models\Models\Rebase.cs"
		"$ScriptRoot\clr\Proviso.Models\Models\Setup.cs"
		"$ScriptRoot\clr\Proviso.Models\Models\Build.cs"
		"$ScriptRoot\clr\Proviso.Models\Models\Deploy.cs"
		"$ScriptRoot\clr\Proviso.Models\Models\Surface.cs"
		"$ScriptRoot\clr\Proviso.Models\Models\Runbook.cs"
		"$ScriptRoot\clr\Proviso.Models\DomainModels\Partition.cs"
		"$ScriptRoot\clr\Proviso.Models\DomainModels\Disk.cs"
		"$ScriptRoot\clr\Proviso.Models\Processing\AssertionResult.cs"
		"$ScriptRoot\clr\Proviso.Models\Processing\ConfigurationError.cs"
		"$ScriptRoot\clr\Proviso.Models\Processing\ConfigurationResult.cs"
		"$ScriptRoot\clr\Proviso.Models\Processing\ConfigEntry.cs"
		"$ScriptRoot\clr\Proviso.Models\Processing\RebaseResult.cs"
		"$ScriptRoot\clr\Proviso.Models\Processing\ValidationError.cs"
		"$ScriptRoot\clr\Proviso.Models\Processing\ValidationResult.cs"
		"$ScriptRoot\clr\Proviso.Models\Processing\SurfaceProcessingResult.cs"
		"$ScriptRoot\clr\Proviso.Models\ProvisoCatalog.cs"
		"$ScriptRoot\clr\Proviso.Models\Orthography.cs"
		"$ScriptRoot\clr\Proviso.Models\DomainCredential.cs"
		"$ScriptRoot\clr\Proviso.Models\ProcessingContext.cs"
		"$ScriptRoot\clr\Proviso.Models\Formatter.cs"
	);
	
	Add-Type -Path $classFiles;
}