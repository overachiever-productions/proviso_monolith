using System.Collections.Generic;

namespace Proviso.Models
{
    public class FacetCatalog
    {
        // TODO: implement as a singleton... 

        // TODO: look at implementing this as an ORDERED dictionary: 
        private Dictionary<string, Facet> _facets;

        public FacetCatalog()
        {
            this._facets = new Dictionary<string, Facet>();
        }

        public int Count
        {
            get { return this._facets.Count; }
        }

        public void AddFacet(Facet added)
        {
            this._facets.Add(added.Name, added);
        }

        public void RemoveFacet(Facet removed)
        {

        }

        public Facet GetFacet(string name)
        {
            if (this._facets.ContainsKey(name))
                return this._facets[name];

            return null;
        }

    }
}
