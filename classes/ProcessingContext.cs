using System.Collections.Generic;

namespace Proviso.Models
{
    public class ProcessingContext
    {
        private Dictionary<string, object> _temporaryValues = new Dictionary<string, object>();
        private readonly Stack<Facet> _facets = new Stack<Facet>();

        public bool ConfigurationEnabled { get; private set; }
        public bool AllowHardReset { get; private set; }

        public bool RebootRequired { get; private set; }
        public string RebootReason { get; private set; }

        private ProcessingContext()
        {
            this.RebootRequired = false;
        }

        public static ProcessingContext Instance => new ProcessingContext();

        public void SetRebootRequired(string reason = null)
        {
            this.RebootRequired = true;
            if (!string.IsNullOrEmpty(reason))
                this.RebootReason = reason;
        }

        public void SetCurrentFacet(Facet added, bool executeConfiguration, bool allowReset)
        {
            this._temporaryValues = new Dictionary<string, object>();
            this._facets.Push(added);

            this.ConfigurationEnabled = executeConfiguration;
            this.AllowHardReset = allowReset;
        }

        public void CloseCurrentFacet()
        {

            this._temporaryValues = new Dictionary<string, object>();
        }

        // REFACTOR: SetFacet[Processing]State(key, value);
        public void StoreTemporaryFacetValue(string key, object value)
        {
            this._temporaryValues.Add(key, value);
        }

        // REFACTOR: GetFacet[Processing]State(key);
        public object GetTemporaryFacetValue(string key)
        {
            if (this._temporaryValues.ContainsKey(key))
                return this._temporaryValues[key];

            return null;
        }
    }
}
