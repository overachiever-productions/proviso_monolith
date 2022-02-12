using System;
using System.Collections.Generic;
using System.Linq;
using Proviso.Enums;
using Proviso.Models;
using Proviso.Processing;

namespace Proviso
{
    public class ProcessingContext
    {
        private Dictionary<string, object> _temporarySurfaceState = new Dictionary<string, object>();
        private readonly Stack<Surface> _surfaces = new Stack<Surface>();  // these never get popped... just using a stack for ordering... 
        private readonly Stack<SurfaceProcessingResult> _processingResults = new Stack<SurfaceProcessingResult>();
        
        public bool RecompareActive { get; private set; }
        public bool ExecuteConfiguration { get; private set; }
        public bool ExecuteRebase { get; private set; }
        public bool RebootRequired { get; private set; }
        public string RebootReason { get; private set; }
        public bool SqlRestartRequired { get; private set; }
        public string SqlRestartReason { get; private set; }
        public Surface LastProcessedSurface => this._surfaces.Count > 0 ? this._surfaces.Peek() : null;
        public SurfaceProcessingResult LastProcessingResult => this._processingResults.Count > 0 ? this._processingResults.Peek() : null;
        public int ProcessedSurfacesCount => this._surfaces.Count;
        public int SurfaceResultsCount => this._processingResults.Count;

        public int SurfaceStateObjectsCount => this._temporarySurfaceState.Count;

        public Runbook CurrentRunbook { get; private set; }
        public string CurrentRunbookVerb { get; private set; }
        public bool CurrentRunbookAllowsReboot { get; private set; }
        public bool CurrentRunbookAllowsSqlRestart { get; private set; }

        public Facet CurrentFacet { get; private set; }
        public string CurrentFacetName { get; private set; }
        public string CurrentKey { get; private set; }
        public object CurrentKeyValue { get; private set; }

        public string CurrentChildKey { get; private set; }
        public object CurrentChildKeyValue { get; private set; }

        public object Expected { get; private set; }
        public object Actual { get; private set; }
        public bool Matched { get; private set; }
        
        //public Dictionary<string, object> TemporarySurfaceState => this._temporarySurfaceState;

        public static ProcessingContext Instance => new ProcessingContext();
        
        private ProcessingContext()
        {
            this.RebootRequired = false;
            this.SqlRestartRequired = false;
            this.RecompareActive = false;

            this.ClearSurfaceState();
        }

        public SurfaceProcessingResult[] GetAllResults()
        {
            return this._processingResults.ToArray()
                .OrderBy(x => x.ProcessingEnd)
                .ToArray();
        }

        public SurfaceProcessingResult[] GetLatestResults(int latest)
        {
            SurfaceProcessingResult[] copy = this._processingResults.ToArray();

            return copy
                .OrderBy(x => x.ProcessingEnd)
                .Take(latest)
                .ToArray();
        }

        public void SetCurrentExpectValue(object value)
        {
            this.Expected = value;
        }

        // TODO: see if these are really needed. they were a bit of a hack around the whole AddSurfaceState vs SETSurfaceState... so..
        //      i'm really curious as to whether they're truly needed or not. 
        public void SetRecompareActive()
        {
            this.RecompareActive = true;
        }

        public void SetRecompareInactive()
        {
            this.RecompareActive = false;
        }

        public void SetValidationState(Facet current)
        {
            this.SetContextStateFromFacet(current);
        }

        public void SetConfigurationState(ValidationResult currentValidation)
        {
            Facet current = currentValidation.ParentFacet;
            if (current == null)
                throw new Exception("Proviso Framework Exception. ValidationResult's Parent [Facet] was/is null. ");

            this.SetContextStateFromFacet(current);

            this.Expected = currentValidation.Expected;
            this.Actual = currentValidation.Actual;
            this.Matched = currentValidation.Matched;
        }

        public void ClearSurfaceState()
        {
            this.CurrentFacet = null;
            this.CurrentFacetName = null;

            this.CurrentKey = null;
            this.CurrentKeyValue = null;
            this.CurrentChildKey = null;
            this.CurrentChildKeyValue = null;

            this.Expected = null;
            this.Actual = null;
        }

        public void SetRebootRequired(string reason = null)
        {
            this.RebootRequired = true;
            if (!string.IsNullOrEmpty(reason))
                this.RebootReason = reason;
        }

        public void SetSqlRestartRequired(string reason = null)
        {
            this.SqlRestartRequired = true;
            if (!string.IsNullOrEmpty(reason))
                this.SqlRestartReason = reason;
        }

        public void StartRunbookProcessing(Runbook started, string verb, bool allowReboot, bool allowSqlRestart)
        {
            this.CurrentRunbook = started;
            this.CurrentRunbookVerb = verb;
            this.CurrentRunbookAllowsReboot = allowReboot;
            this.CurrentRunbookAllowsSqlRestart = allowSqlRestart;
        }

        public void EndRunbookProcessing()
        {
            this.CurrentRunbook = null;
            this.CurrentRunbookVerb = null;
            this.CurrentRunbookAllowsReboot = false;
            this.CurrentRunbookAllowsSqlRestart = false;
        }

        public void SetCurrentSurface(Surface added, bool executeRebase, bool executeConfiguration, SurfaceProcessingResult processingResult)
        {
            this._temporarySurfaceState = new Dictionary<string, object>();
            this._surfaces.Push(added);
            this._processingResults.Push(processingResult);

            this.ExecuteRebase = executeRebase;
            this.ExecuteConfiguration = executeConfiguration;
        }

        public void CloseCurrentSurface()
        {
            this.ClearSurfaceState();
            this._temporarySurfaceState = new Dictionary<string, object>();
        }

        #region Surface State
        public void SetSurfaceState(string key, object value)
        {
            if (this._temporarySurfaceState.ContainsKey(key))
                this._temporarySurfaceState[key] = value;
            else 
                this._temporarySurfaceState.Add(key, value);
        }

        public object GetSurfaceState(string key)
        {
            if (this._temporarySurfaceState.ContainsKey(key))
                return this._temporarySurfaceState[key];

            return null;
        }
        #endregion

        private void SetContextStateFromFacet(Facet current)
        {
            this.CurrentFacet = current;
            this.CurrentFacetName = current.Name;

            switch (current.FacetType)
            {
                case FacetType.Simple:
                    this.CurrentKey = current.Key;
                    this.CurrentKeyValue = current.KeyValue;
                    break;
                case FacetType.Value:
                    this.CurrentKey = current.CurrentIteratorKey;
                    this.CurrentKeyValue = current.CurrentIteratorKeyValue;
                    break;
                case FacetType.Group:
                case FacetType.Compound:
                    this.CurrentKey = current.CurrentIteratorKey;
                    this.CurrentKeyValue = current.CurrentIteratorKeyValue;

                    this.CurrentChildKey = current.CurrentIteratorChildKey;
                    this.CurrentChildKeyValue = current.CurrentIteratorChildKeyValue;
                    break;
                default:
                    throw new Exception("Proviso Exception. Invalid FacetType in CLR ProcessingContext for SetContextStateFromFacet().");
            }
        }
    }
}
