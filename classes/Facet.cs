using System.Collections.Generic;
using System.Management.Automation;

namespace Proviso.Models
{
    public class Facet
    {
        public string Name { get; private set; }
        public string SourceFile { get; private set; }

        // TODO: make these ORDERED lists (or dictionary) ... or (duh) stack/queue... 
        public List<Assertion> Assertions { get; private set; }
        public List<Definition> Definitions { get; private set; }

        public Facet(string name, string sourceFile)
        {
            this.Name = name;
            this.SourceFile = sourceFile;

            this.Assertions = new List<Assertion>();
            this.Definitions = new List<Definition>();
        }

        public void AddAssertion(Assertion added)
        {
            this.Assertions.Add(added);
        }

        public void AddDefinition(Definition added)
        {
            // i THINK this is where they'll be added. 
        }

        public void BindAssertionOutcome(Assertion target, AssertionOutcome outcome)
        {
            // i THINK this is where to do this? 
        }

        public void BindTestOutcome(Definition target, TestOutcome outcome)
        {

        }
    }
}