using System.Management.Automation;

namespace Proviso.Models
{
	public class Assertion
	{
        public string Name { get; private set; }
        public string ParentFacetName { get; private set; }
        public ScriptBlock ScriptBlock { get; private set; }
        public bool NonFatal { get; private set; } 

	    public Assertion(string name, string parentFacetName, ScriptBlock assertionBlock, bool nonFatal)
        {
            this.Name = name;
            this.ParentFacetName = parentFacetName;
            this.ScriptBlock = assertionBlock;
            this.NonFatal = nonFatal;
        }
    }
}
