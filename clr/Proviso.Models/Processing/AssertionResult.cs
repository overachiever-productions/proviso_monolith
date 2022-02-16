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
        public Guid ProcessingId { get; private set; }

        public bool Passed => this.AssertionError == null && this._assertionPassed;
        public bool Failed => !this.Passed;

        public AssertionResult(Assertion assertion, Guid processingId)
        {
            this.Assertion = assertion;
            this.ProcessingId = processingId;
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

        public string GetAssertionName()
        {
            return $"{this.Assertion.Name}";
        }

        public string GetErrorMessage()
        {
            if (this.AssertionError == null && !this._assertionPassed)
                return "Assert Failed. Expected Condition(s) NOT MET.";

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

        public string GetOutcomeState()
        {
            if (this.Passed)
                return "PASS";

            if (this.Assertion.NonFatal)
                return "WARN";

            if(this.AssertionError == null)
                return "FAIL";

            return "FAIL - ERROR: " + this.AssertionError.Exception.Message;
        }
    }
}
