using System.Management.Automation;

namespace Proviso.Models
{
    public class Definition
    {
        public string Description { get; set; }
        public ScriptBlock Expectation { get; private set; }
        public ScriptBlock Test { get; private set; }
        public ScriptBlock Configure { get; private set; }

        public Definition(string description)
        {
            this.Description = description;
        }

        public void AddExpect(ScriptBlock expectation)
        {
            this.Expectation = expectation;
        }

        public void AddTest(ScriptBlock testBlock)
        {
            this.Test = testBlock;
        }

        public void AddConfiguration(ScriptBlock configurationBlock)
        {
            this.Configure = configurationBlock;
        }
    }
}
