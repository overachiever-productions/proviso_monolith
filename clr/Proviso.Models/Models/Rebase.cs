using System.Management.Automation;

namespace Proviso.Models
{
    public class Rebase
    {
        public ScriptBlock RebaseBlock { get; private set; }
        public string ParentSurfaceName { get; private set; }

        public Rebase(ScriptBlock rebaseBlock, string parentSurfaceName)
        {
            this.RebaseBlock = rebaseBlock;
            this.ParentSurfaceName = parentSurfaceName;
        }
    }
}