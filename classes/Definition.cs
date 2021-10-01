using System.Collections.Generic;
using System.Management.Automation;

namespace Proviso.Models
{
    public class Definition
    {
        public string Description { get; set; }
        public ScriptBlock Expectation { get; private set; }
        public ScriptBlock Test { get; private set; }
        public ScriptBlock Configure { get; private set; }
        public TestOutcome Outcome { get; private set; }

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

        //public Definition(ScriptBlock expectation, ScriptBlock test, ScriptBlock configure)
        //{
        //    this.Expectation = expectation;
        //    this.Test = test;
        //    this.Configure = configure;
        //}



        public void SetOutcome(TestOutcome outcome)
        {
            this.Outcome = outcome;
        }
    }
}
