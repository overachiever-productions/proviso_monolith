using System;
using System.Collections.Generic;
using System.Linq;
using Proviso.Models;

namespace Proviso
{
    public class ProvisoCatalog
    {
        private Dictionary<string, Surface> _surfaces = new Dictionary<string, Surface>();
        private Dictionary<string, string> _surfacesByFileName = new Dictionary<string, string>();
        private Dictionary<string, string> _hostNameDefinitions = new Dictionary<string, string>();
        public int SurfaceCount => this._surfaces.Count;

        private List<Runbook> _runbooks = new List<Runbook>();

        private ProvisoCatalog() { }

        public static ProvisoCatalog Instance => new ProvisoCatalog();

        public void AddSurface(Surface added)
        {
            this._surfaces.Add(added.Name, added);
            this._surfacesByFileName.Add(added.FileName, added.Name);
        }

        public Surface GetSurface(string surfaceName)
        {
            if (this._surfaces.ContainsKey(surfaceName))
                return this._surfaces[surfaceName];

            return null;
        }

        public Surface GetSurfaceByFileName(string filename)
        {
            if (this._surfacesByFileName.ContainsKey(filename))
            {
                string surfaceName = this._surfacesByFileName[filename];

                if (this._surfaces.ContainsKey(surfaceName))
                {
                    return this._surfaces[surfaceName];
                }
            }

            return null;
        }
        
        public void AddRunbook(Runbook added)
        {
            if (this._runbooks.Contains(added))
                throw new InvalidOperationException($"Runbook: [{added.Name}] already exists and can NOT be added again.");

            this._runbooks.Add(added);
        }
        
        public List<Runbook> GetRunbooks()
        {
            return this._runbooks;
        }

        public Runbook GetRunbook(string runbookName)
        {
            return this._runbooks.Single(r => r.Name == runbookName);
        }

        public void AddHostDefinition(string name, string path)
        {
            this._hostNameDefinitions.Add(name, path);
        }

        public void ResetHostDefnitions()
        {
            this._hostNameDefinitions = new Dictionary<string, string>();
        }

        public List<string> GetDefinedHostNames()
        {
            return new List<string>(this._hostNameDefinitions.Keys);
        }

        public string GetHostConfigFileByHostName(string hostName)
        {
            return this._hostNameDefinitions[hostName];
        }
    }
}