using System;
using System.Collections.Generic;
using System.Management.Automation;

namespace Proviso.Models
{
    public class FacetManager
    {
        // TODO: look at implementing this as an ORDERED dictionary;
        private readonly Dictionary<string, Facet> _facets = new Dictionary<string, Facet>();
        private static readonly FacetManager _singletonInstance = new FacetManager();
        static FacetManager() { }
        private FacetManager() { }

        public int FacetCount => this._facets.Count;
        
        public static FacetManager GetInstance()
        {
            return _singletonInstance;
        }

        public void AddFacet(Facet added)
        {
            // TODO: figure out writeobject() so'z i can see if I'm getting a singleton or not... 
            this._facets.Add(added.Name, added);
        }

        //public void RemoveFacet(Facet removed)
        //{

        //}

        public Facet GetFacet(string name)
        {
            if (this._facets.ContainsKey(name))
                return this._facets[name];

            return null;
        }
    }
}