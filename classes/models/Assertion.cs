using System.Management.Automation;

namespace Proviso.Models
{
	public class Assertion
	{
        public string Name { get; private set; }
        public string ParentSurfaceName { get; private set; }
        public ScriptBlock ScriptBlock { get; private set; }
        public bool NonFatal { get; private set; } 
        public bool IsNegated { get; private set; }
        public bool IsIgnored { get; private set; }
        public string FailureMessage { get; private set; }

	    public Assertion(string name, string parentSurfaceName, ScriptBlock assertionBlock, string failureMessage, bool nonFatal, bool isIgnored, bool isNegated)
        {
            this.Name = name;
            this.ParentSurfaceName = parentSurfaceName;
            this.ScriptBlock = assertionBlock;
            this.FailureMessage = failureMessage;
            this.NonFatal = nonFatal;
            this.IsIgnored = isIgnored;
            this.IsNegated = isNegated;
        }
    }
}
