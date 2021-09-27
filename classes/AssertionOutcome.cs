
using System;

namespace Proviso.Models
{
    public class AssertionOutcome
    {
        public DateTime Asserted { get; private set; }
        public bool Passed { get; private set; }
        public Exception Exception { get; private set; }

        public AssertionOutcome(bool passed, Exception exception = null)
        {
            this.Asserted = DateTime.Now; // TODO: this might not be the best time to set this. 
            this.Passed = passed;
            this.Exception = exception;
        }
    }
}
