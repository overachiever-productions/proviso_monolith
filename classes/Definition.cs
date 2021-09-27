using System.Collections.Generic;
using System.Management.Automation;

namespace Proviso.Models
{
    public class Definition
    {
        public ScriptBlock Expectation { get; private set; }
        public ScriptBlock Test { get; private set; }
        public ScriptBlock Configure { get; private set; }

        public Definition(ScriptBlock expectation, ScriptBlock test, ScriptBlock configure)
        {
            this.Expectation = expectation;
            this.Test = test;
            this.Configure = configure;
        }
    }
}
