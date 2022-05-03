Set-StrictMode -Version 1.0;

Runbook Tests -DeferRebootUntilRunbookEnd -WaitBeforeRebootFor 5Seconds {
	Run-TestingSurface;
	Run-TestingSurface;
}