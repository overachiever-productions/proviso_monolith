using System.Management.Automation;

namespace Proviso.Models
{
    public class Deploy
    {
        public ScriptBlock DeployBlock { get; private set; }
        public string ParentSurfaceName { get; private set; }

        public Deploy(ScriptBlock deployBlock, string parentSurfaceName)
        {
            this.DeployBlock = deployBlock;
            this.ParentSurfaceName = parentSurfaceName;
        }
    }
}