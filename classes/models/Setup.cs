using System.Management.Automation;

namespace Proviso.Models
{
    public class Setup
    {
        public ScriptBlock SetupBlock { get; private set; }
        public string ParentSurfaceName { get; private set; }

        public Setup(ScriptBlock setupBlock, string parentSurfaceName)
        {
            this.SetupBlock = setupBlock;
            this.ParentSurfaceName = parentSurfaceName;
        }
    }
}