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
        public bool UsesBuild => this.Facets.Any(f => f.UsesBuild);

        public List<Assertion> Assertions { get; private set; }
        public List<Assertion> FailedAssertions { get; private set; }
        public List<Facet> Facets { get; private set; }
        public Setup Setup { get; private set; }
        public Rebase Rebase { get; private set; }

        // vNEXT: 
        //public List<Aspect> Aspects { get; private set; }
        //public List<Build> Builds { get; private set; }
        //public List<Deploy> Deploys { get; private set; }
        public Build Build { get; private set; }
        public Deploy Deploy { get; private set; }

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
                throw new ArgumentException("Setup my ONLY be defined 1x per Surface.");

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
            // vNEXT: this needs to be added to it's current ASPECT... i.e., aspects own facets, builds, and deploys
            this.ValidateFacet(added); // implemented HERE so that we can throw context info about which facets are bad/etc. 
            this.Facets.Add(added);
        }

        public void AddBuild(Build build)
        {
            // vNEXT: this needs to be added to it's current ASPECT... i.e., aspects own facets, builds, and deploys
            if (this.Build != null)
                throw new ArgumentException("Build may ONLY be defined 1x per Surface.");

            this.Build = build;
        }

        public void AddDeploy(Deploy deploy)
        {
            // vNEXT: this needs to be added to it's current ASPECT... i.e., aspects own facets, builds, and deploys
            if (this.Deploy != null)
                throw new ArgumentException("Deploy may ONLY be defined 1x per Surface.");

            this.Deploy = deploy;
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

        public void VerifyCanUseBuild()
        {
            // vNEXT: this'll have to be per Aspect... i.e., one aspect could use Build/Deploy - while another might NOT. 
            if (this.Build == null)
                throw new ArgumentException("Facet can not specify -UsesBuild unless a Build{} block (function) exists within the current Surface.");

            if (this.Deploy == null)
                throw new ArgumentException("Facet can not specify -UsesBuild unless a Deploy{} block (function) exists within the current Surface.");
        }

        private void ValidateFacet(Facet facet)
        {
            // TODO: need to ensure that each facet's NAME is distinct (i.e., can't have the same facet (name) 2x). 
            // further... can't have the same facet with duplicate .ConfigKey properties either.

            // TODO: Revisit... i.e., I disabled the following lines cuz... they were causing problems. 
            // AND... i should be rewriting ALL of this but... need to make sure I'm validating ... so I put an explicit TODO into play... 

            //if(!facet.ExpectIsSet)
            //    throw new Exception($"Facet [{facet.Name}] for Surface [{this.Name}] is invalid. It MUST contain either an [Expect] block, the -Expect switch, or one of the following switches: -ExpectKeyValue, -ExpectValueForCurrentKey, or -ExpectValueForChildKey.");

            if(facet.Test == null)
                throw new Exception($"Facet [{facet.Name}] for Surface [{this.Name}] is invalid. It MUST contain a Test-Block");

            if(facet.Configure == null & facet.UsesBuild == false)
                throw new Exception($"Facet [{facet.Name}] for Surface [{this.Name}] is invalid. It MUST contain a Configure-Block or use the -UsesBuild switch - along with Build{{}} and Deploy{{}} functions.");
        }

        public void Validate()
        {
            if (this.UsesBuild)
                this.VerifyCanUseBuild(); // throws if either Build or Deploy funcs haven't been loaded. 
        }
    }
}