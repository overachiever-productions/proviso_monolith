using System.Management.Automation;

namespace Proviso.Models
{
    public class Runbook
    {
        public string Name { get; private set; }
        public string FileName { get; private set; }
        public string SourcePath { get; private set; }

        public ScriptBlock RunbookBlock { get; private set; }

        public Runbook(string name, string fileName, string sourcePath)
        {
            this.Name = name;
            this.FileName = fileName;
            this.SourcePath = sourcePath;
        }

        public void AddScriptBlock(ScriptBlock runbookBlock)
        {
            this.RunbookBlock = runbookBlock;
        }
    }
}