using System.Collections.Generic;
using Proviso.Models;

namespace Proviso
{
    public class ProvisoCatalog
    {
        private Dictionary<string, Surface> _surfaces = new Dictionary<string, Surface>();
        private Dictionary<string, string> _surfacesByFileName = new Dictionary<string, string>();

        public int SurfaceCount => this._surfaces.Count;

        private ProvisoCatalog() { }

        public static ProvisoCatalog Instance => new ProvisoCatalog();

        public void AddSurface(Surface added)
        {
            this._surfaces.Add(added.Name, added);
            this._surfacesByFileName.Add(added.FileName, added.Name);
        }

        public Surface GetSurface(string facetName)
        {
            if (this._surfaces.ContainsKey(facetName))
                return this._surfaces[facetName];

            return null;
        }

        public Surface GetSurfaceByFileName(string filename)
        {
            if (this._surfacesByFileName.ContainsKey(filename))
            {
                string facetName = this._surfacesByFileName[filename];

                if (this._surfaces.ContainsKey(facetName))
                {
                    return this._surfaces[facetName];
                }
            }

            return null;
        }
    }
}