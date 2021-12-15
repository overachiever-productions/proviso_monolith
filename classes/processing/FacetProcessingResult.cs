using System;
using System.Collections.Generic;
using System.Linq;
using Proviso.Enums;
using Proviso.Models;

namespace Proviso.Processing
{
    public class FacetProcessingResult
    {
        public Facet Facet { get; }
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

        public FacetProcessingState ProcessingState { get; private set; }

        public FacetProcessingState LatestState
        {
            get
            {
                var flags = Enum.GetValues(typeof(FacetProcessingState))
                    .Cast<FacetProcessingState>()
                    .Where(x => this.ProcessingState.HasFlag(x));

                return flags.Max();
            }
        }

        public AssertionsOutcome AssertionsOutcome { get; private set; }
        public List<AssertionResult> AssertionResults { get; private set; }
        public bool AssertionsFailed => this.ProcessingState.HasFlag(FacetProcessingState.AssertsFailed);

        public ValidationsOutcome ValidationsOutcome { get; private set; }
        public List<ValidationResult> ValidationResults { get; private set; }
        public bool ValidationsFailed { get; private set; }

        public RebaseOutcome RebaseOutcome { get; private set; }
        public RebaseResult RebaseResult { get; private set; }
        public bool RebaseFailed => this.ProcessingState.HasFlag(FacetProcessingState.RebaseFailed);

        public ConfigurationsOutcome ConfigurationsOutcome { get; private set; }
        public List<ConfigurationResult> ConfigurationResults { get; private set; }
        public bool ConfigurationsFailed => this.ProcessingState.HasFlag(FacetProcessingState.ConfigurationsFailed);

        public FacetProcessingResult(Facet facet, bool executeConfiguration)
        {
            this.Facet = facet;
            this.ExecuteConfiguration = executeConfiguration;

            this.ProcessingStart = DateTime.Now;
            this.ProcessingState |= FacetProcessingState.Initialized;

            this.AssertionsOutcome = this.Facet.Assertions.Count > 0 ? AssertionsOutcome.UnProcessed : AssertionsOutcome.NoAssertions;
            this.AssertionResults = new List<AssertionResult>();

            this.ValidationsOutcome = ValidationsOutcome.UnProcessed;
            this.ValidationResults = new List<ValidationResult>();

            this.RebaseOutcome = RebaseOutcome.UnProcessed;
            this.RebaseResult = null; 

            this.ConfigurationsOutcome = ConfigurationsOutcome.UnProcessed;
            this.ConfigurationResults = new List<ConfigurationResult>();
        }

        public void StartAssertions()
        {
            this.ProcessingState |= FacetProcessingState.AssertsStarted;
        }

        public void EndAssertions(AssertionsOutcome outcome, List<AssertionResult> assertionResults)
        {
            this.AssertionsOutcome = outcome;
            this.AssertionResults = assertionResults;

            if (outcome == AssertionsOutcome.HardFailure)
            {
                this.ProcessingState |= FacetProcessingState.AssertsFailed;
                this.ProcessingEnd = DateTime.Now;
            }
            else 
                this.ProcessingState |= FacetProcessingState.AssertsSucceeded;
        }

        public void StartValidations()
        {
            this.ProcessingState |= FacetProcessingState.ValidationsStarted;
        }

        public void EndValidations(ValidationsOutcome outcome, List<ValidationResult> results)
        {
            this.ValidationsOutcome = outcome;
            if (outcome == ValidationsOutcome.Failed)
            {
                this.ValidationsFailed = true;
                this.ProcessingState |= FacetProcessingState.ValidationsFailed;
                this.ProcessingEnd = DateTime.Now;
            }
            else
            {
                this.ValidationsFailed = false;
                this.ProcessingState |= FacetProcessingState.ValidationsSucceeded;
            }

            this.ValidationResults = results;
        }

        public void StartRebase()
        {
            if (!this.Facet.RebasePresent)
                throw new InvalidOperationException($"Rebase operations cannot be executed against Facet {this.Facet.Name}; Facet does NOT allow Rebase.");

            this.ProcessingState |= FacetProcessingState.RebaseStarted;
        }

        public void EndRebase(RebaseOutcome outcome, RebaseResult result)
        {
            this.RebaseOutcome = outcome;
            this.RebaseResult = result;

            if (outcome == RebaseOutcome.Success)
                this.ProcessingState |= FacetProcessingState.RebaseSucceeded;
            else
            {
                this.ProcessingState |= FacetProcessingState.RebaseFailed;
                this.ProcessingEnd = DateTime.Now;
            }
        }

        public void StartConfigurations()
        {
            this.ProcessingState |= FacetProcessingState.ConfigurationsStarted;
        }

        public void EndConfigurations(ConfigurationsOutcome outcome, List<ConfigurationResult> results)
        {
            this.ConfigurationsOutcome = outcome;

            switch (outcome)
            {
                case ConfigurationsOutcome.UnProcessed:
                    throw new InvalidOperationException("Configuration State should NOT be UnProcessed. Proviso Framework Error with Process-Facet.ps1.");
                case ConfigurationsOutcome.Failed:
                    this.ProcessingState |= FacetProcessingState.ConfigurationsFailed;
                    break;
                case ConfigurationsOutcome.RecompareFailed:
                    this.ProcessingState |= FacetProcessingState.ConfigurationsFailed;
                    break;
                case ConfigurationsOutcome.Completed:
                    this.ProcessingState |= FacetProcessingState.ConfigurationsSucceeded;
                    break;
            }

            this.ConfigurationResults = results;
        }

        // REFACTOR: Setxxx isn't like the rest of these methods... i.e., change them or change Setxxx
        public void SetProcessingComplete()
        {
            this.ProcessingState |= FacetProcessingState.Succeeded;
            this.ProcessingEnd = DateTime.Now;
        }

        // REFACTOR: Setxxx isn't like the rest of these methods... i.e., change them or change Setxxx
        public void SetProcessingFailed()
        {
            this.ProcessingState |= FacetProcessingState.Failed;
            this.ProcessingEnd = DateTime.Now;
        }

        public string OutcomeSummary()
        {
            string outcome = "Succeeded. ";
            string details = "";

            if (this.LatestState != FacetProcessingState.Succeeded)
            {
                int lower = (int)FacetProcessingState.Succeeded;

                var flags = Enum.GetValues(typeof(FacetProcessingState))
                    .Cast<FacetProcessingState>()
                    .Where (x => ((int)x < lower) & (this.ProcessingState.HasFlag(x)));

                FacetProcessingState errored = flags.Max();

                switch (errored)
                {
                    case FacetProcessingState.AssertsFailed:
                        outcome = "Asserts Failure. ";
                        details = this.GetAssertionsError();
                        break;
                    case FacetProcessingState.ValidationsFailed:
                        outcome = "Validations Exception. ";
                        details = this.GetValidationsError();
                        break;
                    case FacetProcessingState.RebaseFailed:
                        outcome = "Rebase Exception: ";
                        details = this.GetRebaseError();
                        break;
                    case FacetProcessingState.ConfigurationsFailed:
                        outcome = "Configurations Exception. ";
                        details = this.GetConfigurationsError();
                        break;
                    case FacetProcessingState.RecompareFailed:
                        outcome = "Recomparison Failure. ";
                        details = this.GetRecomparisonsError();
                        break;
                    case FacetProcessingState.Failed:
                        outcome = "Unexpected Exception. ";
                        break;
                }

                return $"{outcome.TrimEnd()} {details}";
            }

            switch (this.AssertionsOutcome)
            {
                case AssertionsOutcome.HardFailure:
                    outcome = "Assertion Failure. ";
                    details = "Facet Processing Terminated. ";
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

            if (this.ProcessingState.HasFlag(FacetProcessingState.ValidationsStarted))
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

                    if (!this.ExecuteConfiguration)
                    {
                        outcome = "Complete - but one or more Validations Failed.";
                    }
                }
            }

            if (this.ProcessingState.HasFlag(FacetProcessingState.ConfigurationsStarted))
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
                return $"{this.ConfigurationResults.Count(c => c.RecompareSucceeded)}/{this.ConfigurationResults.Count} Set";

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
