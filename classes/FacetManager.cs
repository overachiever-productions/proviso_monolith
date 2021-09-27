using System;
using System.Collections.Generic;

namespace Proviso.Models
{
    public class FacetManager
    {
        // TODO: look at implementing this as an ORDERED dictionary;
        private readonly Dictionary<string, Facet> _facets = new Dictionary<string, Facet>();
        public int FacetCount
        {
            get { return this._facets.Count; }
        }

        private static readonly FacetManager _singletonInstance = new FacetManager();
        static FacetManager() { }
        private FacetManager() { }

        public static FacetManager GetInstance()
        {
            return _singletonInstance;
        }

        //public static String GetStuff()
        //{
        //    return "this is just a simple test to validate that the stupid class is loading..";
        //}

        public string GetStuff()
        {
            return "it's hard to be dumb.";
        }

        public void AddFacet(Facet added)
        {
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