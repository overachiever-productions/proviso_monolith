using System.Management.Automation;

namespace Proviso.Models
{
    public class Build
    {
        public ScriptBlock BuildBlock { get; private set; }
        public string ParentSurfaceName { get; private set; }

        public Build(ScriptBlock buildBlock, string parentSurfaceName)
        {
            this.BuildBlock = buildBlock;
            this.ParentSurfaceName = parentSurfaceName;
        }
    }
}