using System;
using System.Collections.Generic;
using System.Diagnostics.Eventing.Reader;
using System.Runtime.CompilerServices;
using System.Security.Cryptography;
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
        public FacetProcessingState ProcessingState { get; private set; }

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
            this.ProcessingState = FacetProcessingState.Initialized;

            if (this.Facet.Assertions.Count > 0)
                this.AssertionsOutcome = AssertionsOutcome.UnProcessed;
            else
                this.AssertionsOutcome = AssertionsOutcome.NoAssertions;

            this.AssertionResults = new List<AssertionResult>();

            this.ValidationsOutcome = ValidationsOutcome.UnProcessed;
            this.ValidationResults = new List<ValidationResult>();

            this.RebaseOutcome = RebaseOutcome.UnProcessed;

            this.ConfigurationsOutcome = ConfigurationsOutcome.UnProcessed;
            this.ConfigurationResults = new List<ConfigurationResult>();
        }

        public List<ValidationResult> GetValidationResults()
        {
            return this.ValidationResults;
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
                this.ProcessingState |= FacetProcessingState.AssertsEnded;
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
                this.ProcessingState |= FacetProcessingState.ValidationsEnded;
            }

            this.ValidationResults = results;

            if(!this.ExecuteConfiguration) 
                this.ProcessingEnd = DateTime.Now;
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
                this.ProcessingState |= FacetProcessingState.RebaseEnded;
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
            
        }

        public void SetProcessingComplete()
        {
            this.ProcessingEnd = DateTime.Now;
        }

        public void SetProcessingFailed()
        {
            this.ProcessingState |= FacetProcessingState.Failed;
            this.ProcessingEnd = DateTime.Now;
        }
    }
}
