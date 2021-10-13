using System;
using System.Management.Automation;
using Proviso.Models;

namespace Proviso.Processing
{
    public class AssertionResult
    {
        private bool _assertionPassed = false;

        public Assertion Assertion { get; private set; }
        public ErrorRecord AssertionError { get; private set; }

        public bool Passed => this.AssertionError == null && this._assertionPassed;
        public bool Failed => !this.Passed;

        public AssertionResult(Assertion assertion)
        {
            this.Assertion = assertion;
        }

        public void Complete(bool assertionPassed)
        {
            this._assertionPassed = assertionPassed;
        }

        public void Complete(ErrorRecord errorRecord)
        {
            this._assertionPassed = false;
            this.AssertionError = errorRecord;
        }

        public string GetErrorMessage()
        {
            if (this.AssertionError != null)
            {
                if (this.Assertion.FailureMessage != null)
                {
                    return this.Assertion.FailureMessage + Environment.NewLine + this.AssertionError.Exception.Message;
                }

                return this.AssertionError.Exception.Message;
            }

            return this.Assertion.FailureMessage ?? "Unknown Error.";
        }
    }
}
