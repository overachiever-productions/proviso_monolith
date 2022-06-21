using System;
using System.Collections.Generic;
using System.Linq;
using Proviso.Enums;
using Proviso.Models;

namespace Proviso.Processing
{
    public class SurfaceProcessingResult
    {
        public Surface Surface { get; }
        public bool ExecuteConfiguration { get; }
        public DateTime ProcessingStart { get; }
        public DateTime? ProcessingEnd { get; private set; }
        public TimeSpan? Duration
        {
            get
            {
                if (this.ProcessingEnd.HasValue)
                    return this.ProcessingEnd.Value - this.ProcessingStart;
                return null;
            }
        }

        public Guid ProcessingId { get; private set; }

        public SurfaceProcessingState ProcessingState { get; private set; }

        public SurfaceProcessingState LatestState
        {
            get
            {
                var flags = Enum.GetValues(typeof(SurfaceProcessingState))
                    .Cast<SurfaceProcessingState>()
                    .Where(x => this.ProcessingState.HasFlag(x));

                return flags.Max();
            }
        }

        public AssertionsOutcome AssertionsOutcome { get; private set; }
        public List<AssertionResult> AssertionResults { get; private set; }
        public bool AssertionsFailed => this.ProcessingState.HasFlag(SurfaceProcessingState.AssertsFailed);

        public ValidationsOutcome ValidationsOutcome { get; private set; }
        public List<ValidationResult> ValidationResults { get; private set; }
        public bool ValidationsFailed { get; private set; }

        public bool AllValidationsMatched()
        {
            return !this.ValidationResults.Any(a => a.Failed);
        }
        
        public RebaseOutcome RebaseOutcome { get; private set; }
        public RebaseResult RebaseResult { get; private set; }
        public bool RebaseFailed => this.ProcessingState.HasFlag(SurfaceProcessingState.RebaseFailed);

        public ConfigurationsOutcome ConfigurationsOutcome { get; private set; }
        public List<ConfigurationResult> ConfigurationResults { get; private set; }
        public bool ConfigurationsFailed => this.ProcessingState.HasFlag(SurfaceProcessingState.ConfigurationsFailed);

        public SurfaceProcessingResult(Surface surface, bool executeConfiguration)
        {
            this.Surface = surface;
            this.ExecuteConfiguration = executeConfiguration;
            this.ProcessingId = Guid.NewGuid();

            this.ProcessingStart = DateTime.Now;
            this.ProcessingState |= SurfaceProcessingState.Initialized;

            this.AssertionsOutcome = this.Surface.Assertions.Count > 0 ? AssertionsOutcome.UnProcessed : AssertionsOutcome.NoAssertions;
            this.AssertionResults = new List<AssertionResult>();

            this.ValidationsOutcome = ValidationsOutcome.UnProcessed;
            this.ValidationResults = new List<ValidationResult>();

            this.RebaseOutcome = RebaseOutcome.UnProcessed;
            this.RebaseResult = null; 

            this.ConfigurationsOutcome = ConfigurationsOutcome.UnProcessed;
            this.ConfigurationResults = new List<ConfigurationResult>();
        }

        public ValidationResult GetValidationResultByFacetName(string facetName)
        {
            return this.ValidationResults.First(v => v.ParentFacet.Name == facetName);
        }

        public void StartAssertions()
        {
            this.ProcessingState |= SurfaceProcessingState.AssertsStarted;
        }

        public void EndAssertions(AssertionsOutcome outcome, List<AssertionResult> assertionResults)
        {
            this.AssertionsOutcome = outcome;
            this.AssertionResults = assertionResults;

            if (outcome == AssertionsOutcome.HardFailure)
            {
                this.ProcessingState |= SurfaceProcessingState.AssertsFailed;
                this.ProcessingEnd = DateTime.Now;
            }
            else 
                this.ProcessingState |= SurfaceProcessingState.AssertsSucceeded;
        }

        public void StartValidations()
        {
            this.ProcessingState |= SurfaceProcessingState.ValidationsStarted;
        }

        public void EndValidations(ValidationsOutcome outcome, List<ValidationResult> results)
        {
            this.ValidationsOutcome = outcome;
            if (outcome == ValidationsOutcome.Failed)
            {
                this.ValidationsFailed = true;
                this.ProcessingState |= SurfaceProcessingState.ValidationsFailed;
                this.ProcessingEnd = DateTime.Now;
            }
            else
            {
                this.ValidationsFailed = false;
                this.ProcessingState |= SurfaceProcessingState.ValidationsSucceeded;
            }

            this.ValidationResults = results;
        }

        public void StartRebase()
        {
            if (!this.Surface.RebasePresent)
                throw new InvalidOperationException($"Rebase operations cannot be executed against Surface {this.Surface.Name}; Surface does NOT allow Rebase.");

            this.ProcessingState |= SurfaceProcessingState.RebaseStarted;
        }

        public void EndRebase(RebaseOutcome outcome, RebaseResult result)
        {
            this.RebaseOutcome = outcome;
            this.RebaseResult = result;

            if (outcome == RebaseOutcome.Success)
                this.ProcessingState |= SurfaceProcessingState.RebaseSucceeded;
            else
            {
                this.ProcessingState |= SurfaceProcessingState.RebaseFailed;
                this.ProcessingEnd = DateTime.Now;
            }
        }

        public void StartConfigurations()
        {
            this.ProcessingState |= SurfaceProcessingState.ConfigurationsStarted;
        }

        public void EndConfigurations(ConfigurationsOutcome outcome, List<ConfigurationResult> results)
        {
            this.ConfigurationsOutcome = outcome;

            switch (outcome)
            {
                case ConfigurationsOutcome.UnProcessed:
                    throw new InvalidOperationException("Configuration State should NOT be UnProcessed. Proviso Framework Error with Process-Surface.ps1.");
                case ConfigurationsOutcome.Failed:
                    this.ProcessingState |= SurfaceProcessingState.ConfigurationsFailed;
                    break;
                case ConfigurationsOutcome.RecompareFailed:
                    this.ProcessingState |= SurfaceProcessingState.ConfigurationsFailed;
                    break;
                case ConfigurationsOutcome.Completed:
                    this.ProcessingState |= SurfaceProcessingState.ConfigurationsSucceeded;
                    break;
            }

            this.ConfigurationResults = results;
        }

        // REFACTOR: Setxxx isn't like the rest of these methods... i.e., change them or change Setxxx
        public void SetProcessingComplete()
        {
            this.ProcessingState |= SurfaceProcessingState.Succeeded;
            this.ProcessingEnd = DateTime.Now;
        }

        // REFACTOR: Setxxx isn't like the rest of these methods... i.e., change them or change Setxxx
        public void SetProcessingFailed()
        {
            this.ProcessingState |= SurfaceProcessingState.Failed;
            this.ProcessingEnd = DateTime.Now;
        }

        public string OutcomeSummary()
        {
            string outcome = "Succeeded. ";
            string details = "";

            if (this.LatestState != SurfaceProcessingState.Succeeded)
            {
                int lower = (int)SurfaceProcessingState.Succeeded;

                var flags = Enum.GetValues(typeof(SurfaceProcessingState))
                    .Cast<SurfaceProcessingState>()
                    .Where (x => ((int)x < lower) & (this.ProcessingState.HasFlag(x)));

                SurfaceProcessingState errored = flags.Max();

                switch (errored)
                {
                    case SurfaceProcessingState.AssertsFailed:
                        outcome = "Asserts Failure. ";
                        details = this.GetAssertionsError();
                        break;
                    case SurfaceProcessingState.ValidationsFailed:
                        outcome = "Validations Exception. ";
                        details = this.GetValidationsError();
                        break;
                    case SurfaceProcessingState.RebaseFailed:
                        outcome = "Rebase Exception: ";
                        details = this.GetRebaseError();
                        break;
                    case SurfaceProcessingState.ConfigurationsFailed:
                        outcome = "Configurations Exception. ";
                        details = this.GetConfigurationsError();
                        break;
                    case SurfaceProcessingState.RecompareFailed:
                        outcome = "Recomparison Failure. ";
                        details = this.GetRecomparisonsError();
                        break;
                    case SurfaceProcessingState.Failed:
                        outcome = "Unexpected Exception. ";
                        break;
                }

                return $"{outcome.TrimEnd()} {details}";
            }

            switch (this.AssertionsOutcome)
            {
                case AssertionsOutcome.HardFailure:
                    outcome = "Assertion Failure. ";
                    details = "Surface Processing Terminated. ";
                    break;
                case AssertionsOutcome.UnProcessed:
                    outcome = "Assertion(s) Failure. ";
                    details = "Configuration Error. Assertions are defined as [UnProcessed]. Proviso appears to be broken.";
                    break;
                case AssertionsOutcome.Warning:
                    outcome = "Assertion(s) Warning. ";
                    details = "NOTE: Assertions generated WARNING(s). ";
                    break;
            }

            if (this.ProcessingState.HasFlag(SurfaceProcessingState.ValidationsStarted))
            {
                switch (this.ValidationsOutcome)
                {
                    case ValidationsOutcome.Failed:
                        outcome += "Validation(s) Failure. ";
                        details += "One or more Validations FAILED (i.e., threw an error/exception). ";
                        break;
                    case ValidationsOutcome.UnProcessed:
                        outcome += "Validation(s) Failure. ";
                        details += "Configuration Error. Validations are defined as [UnProcessed]. Proviso appears to be broken. ";
                        break;
                }

                if (this.ValidationResults.Any(v => !v.Matched))
                {
                    outcome = "Complete. ";

                    // Yeah... this is tedious (removing it for now):
                    //if (!this.ExecuteConfiguration)
                    //{
                    //    outcome = "Complete. (NOTE: One or more validations did not match.)";
                    //}
                }
            }

            if (this.ProcessingState.HasFlag(SurfaceProcessingState.ConfigurationsStarted))
            {
                if (this.ExecuteConfiguration)
                {
                    switch (this.ConfigurationsOutcome)
                    {
                        case ConfigurationsOutcome.Failed:
                            outcome = "Exception. ";
                            details += "Exceptions(s) during configuration. ";
                            break;
                        case ConfigurationsOutcome.RecompareFailed:
                            outcome = "Failure. ";
                            details += "One or more configurations failed to SET values as expected.";
                            break;
                        case ConfigurationsOutcome.UnProcessed:
                            break;
                    }
                }
            }

            return $"{outcome.TrimEnd()} {details}";
        }

        public string ValidationsCountSummary()
        {
            if (this.AssertionsFailed)
                return "NOT RUN";

            return $"{this.ValidationResults.Count(v => v.Matched)}/{this.ValidationResults.Count} Passed";
        }

        public string ConfigurationsCountSummary()
        {
            if (this.AssertionsFailed)
                return "NOT RUN";

            if (this.ExecuteConfiguration)
                return $"{this.ConfigurationResults.Count(c => c.ConfigurationFailed == false)}/{this.ConfigurationResults.Count} Set";

            return " - ";
        }

        private string GetAssertionsError()
        {
            return "TODO: Assertions Error.";
        }

        private string GetValidationsError()
        {
            return "TODO: Validations Error.";
        }

        private string GetRebaseError()
        {
            return this.RebaseResult.RebaseError.Exception.Message;
        }

        private string GetConfigurationsError()
        {
            return "TODO: Configurations Error.";
        }

        private string GetRecomparisonsError()
        {
            return "TODO: Recomparisons Error.";
        }
    }
}
