using System.Management.Automation;

namespace Proviso.Models
{
	public class Assertion
	{
        public string Name { get; private set; }
        public string ParentFacetName { get; private set; }
        public ScriptBlock ScriptBlock { get; private set; }

		public AssertionOutcome Outcome { get; private set; }

	    public Assertion(string name, string parentFacetName, ScriptBlock assertionBlock)
        {
            this.Name = name;
            this.ParentFacetName = parentFacetName;
            this.ScriptBlock = assertionBlock;
        }

        public void AssignOutcome(AssertionOutcome assigned)
        {
            this.Outcome = assigned;
        }
	}
}
