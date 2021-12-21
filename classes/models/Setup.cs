using System.Management.Automation;

namespace Proviso.Models
{
    public class Setup
    {
        public ScriptBlock SetupBlock { get; private set; }
        public string ParentFacetName { get; private set; }

        public Setup(ScriptBlock setupBlock, string parentFacetName)
        {
            this.SetupBlock = setupBlock;
            this.ParentFacetName = parentFacetName;
        }
    }
}