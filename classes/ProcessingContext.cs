using System.Collections.Generic;
using Proviso.Models;
using Proviso.Processing;

namespace Proviso
{
    public class ProcessingContext
    {
        private Dictionary<string, object> _temporaryFacetState = new Dictionary<string, object>();
        private readonly Stack<Facet> _facets = new Stack<Facet>();
        private readonly Stack<FacetProcessingResult> _processingResults = new Stack<FacetProcessingResult>();

        public bool ExecuteConfiguration { get; private set; }
        public bool ExecuteRebase { get; private set; }
        public bool RebootRequired { get; private set; }
        public string RebootReason { get; private set; }
        public Facet LastProcessedFacet => this._facets.Count > 0 ? this._facets.Peek() : null;
        public FacetProcessingResult LastProcessingResult => this._processingResults.Count > 0 ? this._processingResults.Peek() : null;
        public int ProcessedFacetsCount => this._facets.Count;
        public int FacetResultsCount => this._processingResults.Count;

        public Dictionary<string, object> TemporaryFacetState => this._temporaryFacetState;

        public static ProcessingContext Instance => new ProcessingContext();
        
        private ProcessingContext()
        {
            this.RebootRequired = false;
        }

        public void SetRebootRequired(string reason = null)
        {
            this.RebootRequired = true;
            if (!string.IsNullOrEmpty(reason))
                this.RebootReason = reason;
        }

        public void SetCurrentRunbook(string runbookName)
        {
            // just a place-holder. i.e., I'll probably end up having a full-blown Runbook object
            // which'll have properties for various details... well, properties for various switches... 
        }

        public void CloseCurrentRunbook()
        {

        }

        public void SetCurrentFacet(Facet added, bool executeRebase, bool executeConfiguration, FacetProcessingResult processingResult)
        {
            this._temporaryFacetState = new Dictionary<string, object>();
            this._facets.Push(added);
            this._processingResults.Push(processingResult);

            this.ExecuteRebase = executeRebase;
            this.ExecuteConfiguration = executeConfiguration;
        }

        public void CloseCurrentFacet()
        {
            this._temporaryFacetState = new Dictionary<string, object>();
        }

        public void AddFacetState(string key, object value)
        {
            this._temporaryFacetState.Add(key, value);
        }

        public object GetFacetState(string key)
        {
            if (this._temporaryFacetState.ContainsKey(key))
                return this._temporaryFacetState[key];

            return null;
        }
    }
}
