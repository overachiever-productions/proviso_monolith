using System.Management.Automation;

namespace Proviso.Models
{
    public class Runbook
    {
        public string Name { get; }
        public string FileName { get; }
        public string SourcePath { get; }

        public ScriptBlock RunbookBlock { get; private set; }

        public bool RequiresDomainCreds { get; private set; }
        public bool RequiresDomainCredsConfigureOnly { get; private set; }
        public bool DeferRebootUntilRunbookEnd { get; private set; }
        public bool SkipSummary { get; private set; }
        public bool SummarizeProblemsOnly { get; private set; }
        public int WaitSecondsBeforeReboot { get; private set; }

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

        public void SetOptions(bool requiresDomainCreds, bool requireDomainCredsConfigOnly, bool deferReboot, bool skipSummary, bool summarizeProblemsOnly, string waitBeforeRebootFor = null)
        {
            this.RequiresDomainCreds = requiresDomainCreds;
            this.RequiresDomainCredsConfigureOnly = requireDomainCredsConfigOnly;
            this.DeferRebootUntilRunbookEnd = deferReboot;
            this.SkipSummary = skipSummary;
            this.SummarizeProblemsOnly = summarizeProblemsOnly;

            if (!string.IsNullOrEmpty(waitBeforeRebootFor))
            {
                string secondsOnly = waitBeforeRebootFor.Replace("Seconds", "");
                this.WaitSecondsBeforeReboot = int.Parse(secondsOnly);
            }
        }
    }
}