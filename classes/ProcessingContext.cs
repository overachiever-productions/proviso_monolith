﻿using System;
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

        public string CurrentKey { get; private set; }
        public object CurrentKeyValue { get; private set; }

        public string CurrentChildKey { get; private set; }
        public object CurrentChildKeyValue { get; private set; }

        public object Expected { get; private set; }
        public object Actual { get; private set; }
        
        public Dictionary<string, object> TemporarySurfaceState => this._temporarySurfaceState;

        public static ProcessingContext Instance => new ProcessingContext();
        
        private ProcessingContext()
        {
            this.RebootRequired = false;
            this.SqlRestartRequired = false;
            this.RecompareActive = false;
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
                    throw new Exception("Proviso Exception. Invalid FacetType in CLR ProcessingContext for .SetValidationState().");
            }
        }

        public void ClearValidationState()
        {
            this.CurrentKey = null;
            this.CurrentKeyValue = null;
            this.CurrentChildKey = null;
            this.CurrentChildKeyValue = null;

            this.Expected = null;  // can/will be set after SetValidationState() is called...
        }

        public void SetConfigurationState(ValidationResult currentValidation)
        {
            Facet current = currentValidation.ParentFacet;
            if (current == null)
                throw new Exception("Proviso Framework Exception. ValidationResult's Parent [Facet] was/is null. ");

            // REFACTOR: this is/was a copy/paste of SetValidationState - i.e., create an internal/private method that assigns state based on def-types... 
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
                    this.CurrentKey = current.CurrentIteratorKey;
                    this.CurrentKeyValue = current.CurrentIteratorKeyValue;

                    this.CurrentChildKey = current.CurrentIteratorChildKey;
                    this.CurrentChildKeyValue = current.CurrentIteratorChildKeyValue;
                    break;
            }

            this.Expected = currentValidation.Expected;
            this.Actual = currentValidation.Actual;
        }

        public void SetDeferredExecution()
        {
            // Hmm... this could just be a switch on/against .SetConfigurationState ... i.e., "bool isDeferred"... 
        }

        public void ClearDeferredExecution()
        {

        }


        public void ClearConfigurationState()
        {
            // REFACTOR ... this is damned near the same as ClearValidationState... to the point where I probably don't need 2x methods... 
            //      could just call it something like "Reset or Clear State"
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

        //public void SetCurrentRunbook(string runbookName)
        //{
        //    // just a place-holder. i.e., I'll probably end up having a full-blown Runbook object
        //    // which'll have properties for various details... well, properties for various switches... 
        //}

        //public void CloseCurrentRunbook()
        //{

        //}

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
            this.ClearConfigurationState();
            this._temporarySurfaceState = new Dictionary<string, object>();
        }

        #region Surface State
        public void AddSurfaceState(string key, object value)
        {
            // vNEXT: this idea of SETTING state may not be the best approach - i.e., I could see something getting 'lost' or 'stuck open' here... 
            //      cuz this is a bit 'fiddly'. 
            //      MIGHT make better sense to simply CHECK to see if the key's value exists and ... if so, simply RESET it to the new value? 
            //      AND, note: this all exists because of RECOMPARE operations - i.e., imagine we do $PVContext.AddSurfaceState("myKey", $someVal); within 
            //          the scope of a test ... well, that's spiffy and all - cuz that value is then available inside of the CONFIGURE operation. 
            //          BUT: when CONFIGURE is done running, we RE-COMPARE results - meaning that TEST is re-run and ... attempting to add _tempFacetState.Add(keyAlreadyDefined, someVal) obviously ... throws. 

            //  THE ABOVE SAID: I've added an explicit: void OverwriteSurfaceState... which addresses SOME concerns - but not all. 
            if (!this.RecompareActive)
                this._temporarySurfaceState.Add(key, value);
        }

        public void OverwriteSurfaceState(string key, object value)
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
    }
}
