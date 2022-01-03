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
        private Dictionary<string, object> _temporaryFacetState = new Dictionary<string, object>();
        private readonly Stack<Facet> _facets = new Stack<Facet>();  // these never get popped... just using a stack for ordering... 
        private readonly Stack<FacetProcessingResult> _processingResults = new Stack<FacetProcessingResult>();
        
        public bool RecompareActive { get; private set; }
        public bool ExecuteConfiguration { get; private set; }
        public bool ExecuteRebase { get; private set; }
        public bool RebootRequired { get; private set; }
        public string RebootReason { get; private set; }
        public Facet LastProcessedFacet => this._facets.Count > 0 ? this._facets.Peek() : null;
        public FacetProcessingResult LastProcessingResult => this._processingResults.Count > 0 ? this._processingResults.Peek() : null;
        public int ProcessedFacetsCount => this._facets.Count;
        public int FacetResultsCount => this._processingResults.Count;

        public int FacetStateObjectsCount => this._temporaryFacetState.Count;

        public string CurrentKey { get; private set; }
        public object CurrentKeyValue { get; private set; }

        public string CurrentChildKey { get; private set; }
        public object CurrentChildKeyValue { get; private set; }

        public object Expected { get; private set; }
        public object Actual { get; private set; }
        
        public Dictionary<string, object> TemporaryFacetState => this._temporaryFacetState;

        public static ProcessingContext Instance => new ProcessingContext();
        
        private ProcessingContext()
        {
            this.RebootRequired = false;
            this.RecompareActive = false;
        }

        public FacetProcessingResult[] GetAllResults()
        {
            return this._processingResults.ToArray()
                .OrderBy(x => x.ProcessingEnd)
                .ToArray();
        }

        public FacetProcessingResult[] GetLatestResults(int latest)
        {
            FacetProcessingResult[] copy = this._processingResults.ToArray();

            return copy
                .OrderBy(x => x.ProcessingEnd)
                .Take(latest)
                .ToArray();
        }

        public void SetCurrentExpectValue(object value)
        {
            this.Expected = value;
        }

        //public void SetCurrentActualValue(object value)
        //{
        //    this.Actual = value;
        //}

        public void SetRecompareActive()
        {
            this.RecompareActive = true;
        }

        public void SetRecompareInactive()
        {
            this.RecompareActive = false;
        }

        public void SetValidationState(Definition current)
        {
            switch (current.DefinitionType)
            {
                case DefinitionType.Simple:
                    this.CurrentKey = current.Key;
                    this.CurrentKeyValue = current.KeyValue;
                    break;
                case DefinitionType.Value:
                    this.CurrentKey = current.CurrentIteratorKey;
                    this.CurrentKeyValue = current.CurrentIteratorKeyValue;
                    break;
                case DefinitionType.Group:
                case DefinitionType.Compound:
                    this.CurrentKey = current.CurrentIteratorKey;
                    this.CurrentKeyValue = current.CurrentIteratorKeyValue;

                    this.CurrentChildKey = current.CurrentIteratorChildKey;
                    this.CurrentChildKeyValue = current.CurrentIteratorChildKeyValue;
                    break;
                default: 
                    throw new Exception("Proviso Exception. Invalid DefinitionType in CLR ProcessingContext for .SetValidationState().");
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
            Definition current = currentValidation.ParentDefinition;
            if (current == null)
                throw new Exception("Proviso Framework Exception. ValidationResult's Parent [Definition] was/is null. ");

            // REFACTOR: this is/was a copy/paste of SetValidationState - i.e., create an internal/private method that assigns state based on def-types... 
            switch (current.DefinitionType)
            {
                case DefinitionType.Simple:
                    this.CurrentKey = current.Key;
                    this.CurrentKeyValue = current.KeyValue;
                    break;
                case DefinitionType.Value:
                    this.CurrentKey = current.CurrentIteratorKey;
                    this.CurrentKeyValue = current.CurrentIteratorKeyValue;
                    break;
                case DefinitionType.Group:
                    this.CurrentKey = current.CurrentIteratorKey;
                    this.CurrentKeyValue = current.CurrentIteratorKeyValue;

                    this.CurrentChildKey = current.CurrentIteratorChildKey;
                    this.CurrentChildKeyValue = current.CurrentIteratorChildKeyValue;
                    break;
            }

            this.Expected = currentValidation.Expected;
            this.Actual = currentValidation.Actual;
        }

        public void ClearConfigurationState()
        {
            // REFACTOR ... this is damned near the same as ClearValidationState... the the point where I probably don't need 2x methods... 
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

        //public void SetCurrentRunbook(string runbookName)
        //{
        //    // just a place-holder. i.e., I'll probably end up having a full-blown Runbook object
        //    // which'll have properties for various details... well, properties for various switches... 
        //}

        //public void CloseCurrentRunbook()
        //{

        //}

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
            this.ClearConfigurationState();
            this._temporaryFacetState = new Dictionary<string, object>();
        }

        public void AddFacetState(string key, object value)
        {
            // vNEXT: this idea of SETTING state may not be the best approach - i.e., I could see something getting 'lost' or 'stuck open' here... 
            //      cuz this is a bit 'fiddly'. 
            //      MIGHT make better sense to simply CHECK to see if the key's value exists and ... if so, simply RESET it to the new value? 
            //      AND, note: this all exists because of RECOMPARE operations - i.e., imagine we do $PVContext.AddFacetState("myKey", $someVal); within 
            //          the scope of a test ... well, that's spiffy and all - cuz that value is then available inside of the CONFIGURE operation. 
            //          BUT: when CONFIGURE is done running, we RE-COMPARE results - meaning that TEST is re-run and ... attempting to add _tempFacetState.Add(keyAlreadyDefined, someVal) obviously ... throws. 

            //  THE ABOVE SAID: I've added an explicit: void OverwriteFacetState... which addresses SOME concerns - but not all. 
            if (!this.RecompareActive)
                this._temporaryFacetState.Add(key, value);
        }

        public void OverwriteFacetState(string key, object value)
        {
            if (this._temporaryFacetState.ContainsKey(key))
                this._temporaryFacetState[key] = value;
            else 
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
