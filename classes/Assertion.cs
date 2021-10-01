using System;
using System.Management.Automation;

namespace Proviso.Models
{
	public class Assertion
	{
        private bool _failed = true;

        public string Name { get; private set; }
        public string ParentFacetName { get; private set; }
        public ScriptBlock ScriptBlock { get; private set; }
        public bool NonFatal { get; private set; } 

        public DateTime? AssertionStarted { get; private set; }
        public DateTime? AssertionEnded { get; private set; }
        public ErrorRecord AssertionError { get; private set; }

        public bool Failed
        {
            get
            {
                if (!this.AssertionStarted.HasValue)
                {
                    var ex = new InvalidOperationException("Assertion has not yet been tested. Failed can only be evaluated AFTER testing.");
                    var er = new ErrorRecord(ex, "Proviso.Models.Assertion.InvalidCheck.Start", ErrorCategory.InvalidOperation, this);
                    this.SetAssertionFailure(er);
                }

                if (!this.AssertionEnded.HasValue)
                {
                    var ex = new Exception("Unknown problem. Assertion was started, but not marked as complete. Assuming Failure.");
                    var er = new ErrorRecord(ex, "Proviso.Models.Assertion.InvalidCheck.End", ErrorCategory.InvalidOperation, this);
                    this.SetAssertionFailure(er);
                }

                return _failed;
            }
        }

	    public Assertion(string name, string parentFacetName, ScriptBlock assertionBlock, bool nonFatal)
        {
            this.Name = name;
            this.ParentFacetName = parentFacetName;
            this.ScriptBlock = assertionBlock;
            this.NonFatal = nonFatal;
        }

        public void SetAssertionStarted()
        {
            this.AssertionStarted = DateTime.Now;
        }

        public void SetAssertionSuccess()
        {
            this._failed = false;
            this.AssertionEnded = DateTime.Now;
        }

        public void SetAssertionFailure(ErrorRecord errorRecord)
        {
            this._failed = true;
            this.AssertionError = errorRecord;
            this.AssertionEnded = DateTime.Now;
        }
    }
}
