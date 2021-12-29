using System.Management.Automation;

namespace Proviso.Models
{
    public class Rebase
    {
        public ScriptBlock RebaseBlock { get; private set; }
        public string ParentFacetName { get; private set; }

        public Rebase(ScriptBlock rebaseBlock, string parentFacetName)
        {
            this.RebaseBlock = rebaseBlock;
            this.ParentFacetName = parentFacetName;
        }
    }
}