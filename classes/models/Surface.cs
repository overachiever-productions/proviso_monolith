using System;
using System.Collections.Generic;
using System.Linq;
using Proviso.Enums;

namespace Proviso.Models
{
    public class Surface
    {
        public string Name { get; private set; }
        public string FileName { get; private set; }
        public string SourcePath { get; private set; }
        public string ConfigKey { get; private set; }

        public bool RebasePresent => this.Rebase != null;
        public bool DefersConfigurations => this.Facets.Any(d => d.DefersConfiguration);

        public List<Assertion> Assertions { get; private set; }
        public List<Assertion> FailedAssertions { get; private set; }
        public List<Facet> Facets { get; private set; }
        public Setup Setup { get; private set; }
        public Rebase Rebase { get; private set; }

        public Surface(string name, string fileName, string sourcePath)
        {
            this.Name = name;
            this.FileName = fileName;
            this.SourcePath = sourcePath;

            this.Assertions = new List<Assertion>();
            this.FailedAssertions = new List<Assertion>(); // TODO: I probably don't NEED 2x different lists/sets of assertions. Probably makes MORE SENSE to mark existing assertions as FAILED... 
            this.Facets = new List<Facet>();
        }

        public void AddAssertion(Assertion added)
        {
            this.Assertions.Add(added);
        }

        public void AddSetup(Setup setup)
        {
            if (this.Setup != null)
                throw new ArgumentException("Setup my ONLY be defined 1x per surface.");

            this.Setup = setup;
        }
        
        public void AddRebase(Rebase added)
        {
            if (this.Rebase != null)
                throw new ArgumentException("Rebase may NOT be set more than one time.");

            this.Rebase = added;
        }

        public void AddFacet(Facet added)
        {
            this.ValidateFacet(added); // implemented HERE so that we can throw context info about which facets are bad/etc. 
            this.Facets.Add(added);
        }

        public void AddConfigKey(string key)
        {
            this.ConfigKey = key;
        }

        public List<Facet> GetSimpleFacets()
        {
            return this.Facets.Where(d => d.FacetType == FacetType.Simple).ToList();
        }

        public List<Facet> GetBaseValueFacets()
        {
            return this.Facets.Where(d => d.FacetType == FacetType.Value).ToList();
        }

        public List<Facet> GetBaseGroupFacets()
        {
            return this.Facets.Where(d => d.FacetType == FacetType.Group).ToList();
        }

        public List<Facet> GetBaseCompoundFacets()
        {
            return this.Facets.Where(d => d.FacetType == FacetType.Compound).ToList();
        }

        public void VerifyConfiguredBy(string currentFacetDescription, string handlerFacetDescription)
        {
            Facet handler = this.Facets.SingleOrDefault(d => d.Description == handlerFacetDescription);
            if(handler == null)
                throw new Exception($"Facet [{currentFacetDescription}] specifies -ConfiguredBy [{handlerFacetDescription}] - but a Facet with a Description of [{handlerFacetDescription}] does not (yet?) exist.");

            if(handler.ConfiguredBy != null)
                throw new Exception($"Facet [{currentFacetDescription}] specifies -ConfiguredBy [{handlerFacetDescription}] - but Facet [{handlerFacetDescription}] specifies -ConfiguredBy as well (vs an explicit Configure block). The -ConfiguredBy switch can NOT be 'chained' or 're-pointed'.");
        }

        private void ValidateFacet(Facet facet)
        {
            // TODO: need to ensure that each facet's NAME is distinct (i.e., can't have the same facet (name) 2x). 
            // further... can't have the same facet with duplicate .ConfigKey properties either.

            if(!facet.ExpectIsSet)
                throw new Exception($"Facet [{facet.Description}] for Surface [{this.Name}] is invalid. It MUST contain either an [Expect] block, the -Except switch, or one of the following switches: -ExpectKeyValue, -ExpectValueForCurrentKey, or -ExpectValueForChildKey.");

            if(facet.Test == null)
                throw new Exception($"Facet [{facet.Description}] for Surface [{this.Name}] is invalid. It MUST contain a Test-Block");

            if(facet.Configure == null & facet.ConfiguredBy == null)
                throw new Exception($"Facet [{facet.Description}] for Surface [{this.Name}] is invalid. It MUST contain a Configure-Block.");
        }
    }
}