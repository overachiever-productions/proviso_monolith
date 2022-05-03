using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.PowerShell.Commands;
using Proviso.Enums;
using Proviso.Models;
using Proviso.Processing;

namespace Proviso
{
    public class ProcessingContext
    {
        private Dictionary<string, object> _temporarySurfaceState = new Dictionary<string, object>();

        private Stack<SurfaceProcessingResult> _processingResults = new Stack<SurfaceProcessingResult>();
        private Stack<Guid> _runbookProcessingIds = new Stack<Guid>();
        private Dictionary<Guid, int> _surfaceCountsByRunbookProcessingIds = new Dictionary<Guid, int>();

        private Guid _currentRunbookProcessingId;
        
        public bool ExecuteConfiguration { get; private set; }
        public bool ExecuteRebase { get; private set; }

        public Runbook CurrentRunbook { get; private set; }
        public string CurrentRunbookVerb { get; private set; }
        public bool CurrentRunbookAllowsReboot { get; private set; }
        public bool CurrentRunbookAllowsSqlRestart { get; private set; }

        public Surface CurrentSurface { get; private set; }

        public Facet CurrentFacet { get; private set; }
        public string CurrentFacetName { get; private set; }

        private string _currentSqlInstance;
        public string CurrentSqlInstance 
        {
            get
            {
               if(string.IsNullOrWhiteSpace(this._currentSqlInstance))
                    return "MSSQLSERVER";

               return this._currentSqlInstance;
            }
            set
            {
                this._currentSqlInstance = value;
            }
        }
        public object CurrentObjectName { get; private set; }
        public string CurrentConfigKey { get; private set; }
        public object CurrentConfigKeyValue { get; private set; }

        public object Expected { get; private set; }
        public object Actual { get; private set; }
        public bool Matched { get; private set; }

        public bool RebootRequired { get; private set; }
        public string RebootReason { get; private set; }
        public bool SqlRestartRequired { get; private set; }
        public string SqlRestartReason { get; private set; }

        public static ProcessingContext Instance => new ProcessingContext();
        
        private ProcessingContext()
        {
            this.RebootRequired = false;
            this.SqlRestartRequired = false;

            this.ClearSurfaceState();
        }

        public SurfaceProcessingResult[] GetAllResults()
        {
            return this._processingResults.ToArray()
                .OrderByDescending(x => x.ProcessingEnd)
                .ToArray();
        }

        public SurfaceProcessingResult[] GetLatestResults(int latest)
        {
            SurfaceProcessingResult[] copy = this._processingResults.ToArray();

            return copy
                .OrderByDescending(x => x.ProcessingStart)
                .Take(latest)
                .ToArray();
        }

        public SurfaceProcessingResult[] GetLatestRunbookResults()
        {
            if (this._runbookProcessingIds.Count < 1)
                throw new InvalidOperationException("ProcessingContext.GetLatestRunbookResults can NOT be called unless/until Runbooks have been executed.");

            //if(latest > 1) 
            //    throw new NotImplementedException("Proviso Framework Error. Retrieving > 1x Runbook's worth of results is not yet supported.");

            //if (this._runbookProcessingIds.Count < latest)
            //    latest = this._runbookProcessingIds.Count; // or... is it .Count -1? 

            // get the last N Guids from this._runbookProcessingIds -> but... those values have to ORDERED/sorted. 
            //      i pull this off with SURFACES, because they have a .ProcessingStart property that I can use... 
            //      but, currently, Runbooks don't have a RunbookProcessingResult object that I can use in a similar fashion. 
            //          So, there are 2x main options here: 
            //              a. implement either a Tuple<Guid, DateTime> and ... order-by the timestamp... descending. 
            //              a`. create some sort of full-blown object and sort by that... similar to the above - just more explicit... 
            //              b. Use a Linked List and pull .Last and .Last.Next.Next, etc. until we're done grabbing - assuming that works. 

            //         then, once i've got all of the above, simply 'sum' the total number of surfaces per each... i.e., if 3x runbooks ran with 2, 6, 3 surfaces each... 
            //                  no matter which ones are first/last/whatever... that's 11 surfaces total - so get the last 11x surfaces... 

            // otherwise, this, currently, works as a bit of an odd hack/work-around: 
            int processedSurfacesCountFromMostRecent = this._surfaceCountsByRunbookProcessingIds[this._currentRunbookProcessingId];   // this guy will always be the 'last'/most-recent one processed.. 

            return this.GetLatestResults(processedSurfacesCountFromMostRecent);
        }

        public void SetCurrentExpectValue(object value)
        {
            this.Expected = value;
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

        private void SetContextStateFromFacet(Facet current)
        {
            this.CurrentFacet = current;
            this.CurrentFacetName = current.Name;

            if (current.FacetType == FacetType.NonKey)
                this.ClearSurfaceState();  // there's nothing to set - so... make sure everything is clear/cleaned-out.
            else
            {
                this.CurrentSqlInstance = current.CurrentSqlInstanceName;
                this.CurrentObjectName = current.CurrentObjectName;
                this.CurrentConfigKey = current.CurrentKey;
                this.CurrentConfigKeyValue = current.CurrentKeyValue;
            }
        }

        public void ClearSurfaceState()
        {
            this.CurrentFacet = null;
            this.CurrentFacetName = null;

            this.CurrentSqlInstance = null;
            this.CurrentObjectName = null;
            this.CurrentConfigKey = null;
            this.CurrentConfigKeyValue = null;

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

            this._currentRunbookProcessingId = Guid.NewGuid();
            this._runbookProcessingIds.Push(this._currentRunbookProcessingId);
            this._surfaceCountsByRunbookProcessingIds.Add(this._currentRunbookProcessingId, 0);
        }

        public void EndRunbookProcessing()
        {
            this.CurrentRunbook = null;
            this.CurrentRunbookVerb = null;
            this.CurrentRunbookAllowsReboot = false;
            this.CurrentRunbookAllowsSqlRestart = false;
            
            //this._currentRunbookProcessingId = null;  // meh, don't really need, cuz any attempt to use this (in this class only) checks to see if we're IN a runbook or not.
        }

        public void SetCurrentSurface(Surface added, bool executeRebase, bool executeConfiguration, SurfaceProcessingResult processingResult)
        {
            this.CurrentSurface = added;
            this.ExecuteRebase = executeRebase;
            this.ExecuteConfiguration = executeConfiguration;

            this._temporarySurfaceState = new Dictionary<string, object>();

            this._processingResults.Push(processingResult);

            if (this.CurrentRunbook != null)
            {
                this._surfaceCountsByRunbookProcessingIds[this._currentRunbookProcessingId]++;
            }
        }

        public void CloseCurrentSurface()
        {
            this.ClearSurfaceState();
            this._temporarySurfaceState = new Dictionary<string, object>();
        }

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
    }
}
