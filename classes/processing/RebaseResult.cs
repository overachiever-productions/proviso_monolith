using System;
using System.Management.Automation;
using Proviso.Enums;
using Proviso.Models;

namespace Proviso.Processing
{
    public class RebaseResult
    {
        public Rebase Rebase { get; private set; }
        public ErrorRecord RebaseError { get; private set; }
        public RebaseOutcome RebaseOutcome { get; private set; }
        public Guid ProcessingId { get; private set; }

        public RebaseResult(Rebase rebase, Guid processingId)
        {
            this.Rebase = rebase;
            this.ProcessingId = processingId;

            this.RebaseOutcome = RebaseOutcome.UnProcessed;
        }

        public void SetSuccess()
        {
            this.RebaseOutcome = RebaseOutcome.Success;
        }

        public void SetFailure(ErrorRecord error)
        {
            this.RebaseError = error;
            this.RebaseOutcome = RebaseOutcome.Failure;
        }

        public string GetFacetName()
        {
            return this.Rebase.ParentFacetName;
        }

        public string GetOutcomeSummary()
        {
            switch (this.RebaseOutcome)
            {
                case RebaseOutcome.UnProcessed:
                    return "Configuration Problem. Rebase is listed as UnProcessed. Framework error/problem with Proviso.";
                //case RebaseOutcome.Success:
                case RebaseOutcome.Failure:
                    return "Rebase Exception: " + this.RebaseError.Exception.Message;
            }

            return "Rebase Succeeded.";
        }
    }
}
