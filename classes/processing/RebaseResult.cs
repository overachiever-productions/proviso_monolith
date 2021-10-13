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

        public RebaseResult(Rebase rebase)
        {
            this.Rebase = rebase;
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
    }
}
