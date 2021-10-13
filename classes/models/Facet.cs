using System;
using System.Collections.Generic;

namespace Proviso.Models
{
    public class Facet
    {
        public string Name { get; private set; }
        public string FileName { get; private set; }
        public string SourcePath { get; private set; }

        public bool RebasePresent => this.Rebase != null;

        public List<Assertion> Assertions { get; private set; }
        public List<Assertion> FailedAssertions { get; private set; }
        public List<Definition> Definitions { get; private set; }
        public Rebase Rebase { get; private set; }

        public Facet(string name, string fileName, string sourcePath)
        {
            this.Name = name;
            this.FileName = fileName;
            this.SourcePath = sourcePath;

            this.Assertions = new List<Assertion>();
            this.FailedAssertions = new List<Assertion>(); // TODO: I probably don't NEED 2x different lists/sets of assertions. Probably makes MORE SENSE to mark existing assertions as FAILED... 
            this.Definitions = new List<Definition>();
        }

        public void AddAssertion(Assertion added)
        {
            this.Assertions.Add(added);
        }

        public void AddRebase(Rebase added)
        {
            if (this.Rebase != null)
                throw new ArgumentException("Rebase may NOT be set more than one time.");

            this.Rebase = added;
        }

        public void AddDefinition(Definition added)
        {
            this.Definitions.Add(added);
        }
    }
}