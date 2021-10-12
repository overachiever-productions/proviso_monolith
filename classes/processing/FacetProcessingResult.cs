using System;
using System.Collections.Generic;
using Proviso.Enums;
using Proviso.Models;

namespace Proviso.Processing
{
    public class FacetProcessingResult
    {

        public Facet Facet { get; private set; }
        public bool ExecuteConfiguration { get; private set; }
        public DateTime ProcessingStart { get; private set; }
        public DateTime? ProcessingEnd { get; private set; }

        public AssertionsOutcome AssertionsOutcome { get; private set; }
        public List<AssertionResult> AssertionResults { get; private set; }
        public ValidationsOutcome ValidationsOutcome { get; private set; }
        public bool ValidationsFailed { get; private set; }
        public List<ValidationResult> ValidationResults { get; private set; }
 
        public FacetProcessingState ProcessingState { get; private set; }

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



        }

        public List<ValidationResult> GetValidationResults()
        {
            return this.ValidationResults;
        }

        public void StartProcessingAssertions()
        {
            this.ProcessingState |= FacetProcessingState.AssertsStarted;
        }

        public void EndProcessingAssertions(AssertionsOutcome outcome, List<AssertionResult> assertionResults)
        {
            this.AssertionsOutcome = outcome;
            this.AssertionResults = assertionResults;

            if (outcome == AssertionsOutcome.HardFailure)
                this.ProcessingState |= FacetProcessingState.AssertsFailed; 
            else 
                this.ProcessingState |= FacetProcessingState.AssertsEnded;
        }

        public void StartProcessingValidations()
        {
            this.ProcessingState |= FacetProcessingState.ValidationsStarted;
        }

        public void EndProcessingValidations(ValidationsOutcome outcome, List<ValidationResult> results)
        {
            this.ValidationsOutcome = outcome;
            if (outcome == ValidationsOutcome.Failed)
            {
                this.ValidationsFailed = true;
                this.ProcessingState |= FacetProcessingState.ValidationsFailed;
            }
            else
            {
                this.ValidationsFailed = false;
                this.ProcessingState |= FacetProcessingState.ValidationsEnded;
            }

            this.ValidationResults = results;
        }

        public void StartProcessingRebase()
        {
            if (!this.Facet.AllowsReset)
                throw new InvalidOperationException($"Rebase operations cannot be executed against Facet {this.Facet.Name}; Facet does NOT allow Rebase.");

            this.ProcessingState |= FacetProcessingState.RebaseStarted;
        }

        // TODO: add either a RebaseError or a RebaseResult (probably Result - that's what I'm doing elsewhere).
        public void EndProcessingRebase(RebaseOutcome outcome)
        {
            this.ProcessingState |= FacetProcessingState.RebaseEnded;
        }

        public void StartProcessingConfiguration()
        {
            this.ProcessingState |= FacetProcessingState.ConfigurationsStarted;
        }

        public void EndProcessingConfiguration()
        {

        }

        public void StartProcessingRecompare()
        {
            // TODO: don't allow if ConfigureStarted/Ended don't exist... 
            // i.e., OR (or AND?) those 2 together... and run a single check to see if they both exist... 
        }

        public void EndProcessingRecompare()
        {

        }

        public void AddProcessingFailure()
        {
            this.ProcessingState |= FacetProcessingState.Failed;
        }
    }
}
