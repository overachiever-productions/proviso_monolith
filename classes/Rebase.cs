using System.Management.Automation;

namespace Proviso.Models
{
    public class Rebase
    {
        public ScriptBlock RebaseBlock { get; set; }
        public string ParentFacetName { get; set; }
        public RebaseOutcome RebaseOutcome { get; set; }

        public Rebase(ScriptBlock rebaseBlock, string parentFacetName)
        {
            this.RebaseBlock = rebaseBlock;
            this.ParentFacetName = parentFacetName;
        }

        public void AddOutcome(RebaseOutcome outcome)
        {
            this.RebaseOutcome = outcome;
        }
    }
}