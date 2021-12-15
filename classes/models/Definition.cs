using System;
using System.Management.Automation;

namespace Proviso.Models
{
    public class Definition
    {
        public Facet Parent { get; set; }
        public string Description { get; set; }
        public ScriptBlock Expectation { get; private set; }
        public string Key { get; private set; }
        public ScriptBlock Test { get; private set; }
        public ScriptBlock Configure { get; private set; }

        public Definition(Facet parent, string description)
        {
            this.Parent = parent;
            this.Description = description;
        }

        public void AddKey(string key)
        {
            if (this.Expectation != null)
                throw new InvalidOperationException("An Expect-block has already been provided. Definitions can use EITHER a Key or an Expect-block.");
            
            this.Key = key;
        }

        public void AddExpect(ScriptBlock expectation)
        {
            if (this.Key != null)
                throw new InvalidOperationException("A -Key for this Definition has already been provided. Definitions can use EITHER a KEY or an Expect-block.");

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
