using System;
using System.Management.Automation;

namespace Proviso.Models
{
	public class Assertion
	{
        public string Name { get; private set; }
        public string ParentFacetName { get; private set; }
        public ScriptBlock ScriptBlock { get; private set; }
        public bool Fatal { get; private set; } 

		public AssertionOutcome Outcome { get; private set; }

	    public Assertion(string name, string parentFacetName, ScriptBlock assertionBlock, bool fatal)
        {
            this.Name = name;
            this.ParentFacetName = parentFacetName;
            this.ScriptBlock = assertionBlock;
            this.Fatal = fatal;
        }

        public void AssignOutcome(AssertionOutcome assigned)
        {
            this.Outcome = assigned;

            if (Fatal)
            {
                throw new Exception("Need a custom exception that i can trap... or maybe not an exception??");
                // yeah... a better idea would be ... run checks for fatal INSIDE of the processor itself.
            }
        }
	}
}
