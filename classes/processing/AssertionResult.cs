using System;
using System.Management.Automation;
using Proviso.Models;

namespace Proviso.Processing
{
    public class AssertionResult
    {
        private bool _failed = true;

        public Assertion Assertion { get; private set; }
        public DateTime AssertionStarted { get; private set; }
        public DateTime? AssertionEnded { get; private set; }
        public ErrorRecord AssertionError { get; private set; }

        public AssertionResult(Assertion assertion)
        {
            this.Assertion = assertion;
            this.AssertionStarted = DateTime.Now;
        }

        public bool Failed
        {
            get
            {
                if (!this.AssertionEnded.HasValue)
                {
                    var ex = new Exception("Unknown problem. Assertion was started, but not marked as complete. Assuming Failure.");
                    var er = new ErrorRecord(ex, "Proviso.Models.Assertion.InvalidCheck.End", ErrorCategory.InvalidOperation, this);
                    this.Complete(er);
                }

                return _failed;
            }
        }

        public void Complete()
        {
            this._failed = false;
            this.AssertionEnded = DateTime.Now;
        }

        public void Complete(ErrorRecord errorRecord)
        {
            this._failed = true;
            this.AssertionError = errorRecord;
            this.AssertionEnded = DateTime.Now;
        }
    }
}
