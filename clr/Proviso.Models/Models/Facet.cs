﻿using System.Management.Automation;
using Proviso.Enums;

namespace Proviso.Models
{
    public class Facet
    {
        public Surface Parent { get; }
        public FacetType FacetType { get; }
        public string Name { get; }
        public ScriptBlock Test { get; private set; }
        public ScriptBlock Configure { get; private set; }
        public ScriptBlock Expect { get; private set; }

        public bool UsesBuild { get; private set; }

        public bool ExpectStaticKey { get; private set; }
        public bool ExpectCurrentIterationKey { get; private set; }
        public bool ExpectCompoundValueKey { get; private set; }
        public bool ExpectGroupChildKey { get; private set; }
        public bool ExpectIsSet { get; private set; }

        public bool RequiresReboot { get; private set; }
        public string Key { get; private set; }                 // 'static' key sent in via -Key "xxx" argument... (for simple/scalar Facets).
        public object KeyValue { get; private set; }
        
        public string IterationKey { get; private set; }        // Key used for 'looping' over Value(Array) keys or Group keys... 
        public string CompoundIterationKey { get; private set; }
        public string ChildKey { get; private set; }            // used ONLY for/by Group keys ... 
        public string OrderByChildKey { get; private set; }     //      ONLY used for Group Keys... 
        public bool OrderDescending { get; private set; }       //      ONLY used for Array/Value keys

        public string CurrentIteratorKey { get; private set; }
        public object CurrentIteratorKeyValue { get; private set; }
        public string CurrentIteratorChildKey { get; private set; }
        public object CurrentIteratorChildKeyValue { get; private set; }

        public Facet(Surface parent, string name, FacetType type)
        {
            this.Parent = parent;
            this.Name = name;
            this.FacetType = type;

            this.RequiresReboot = false;
            this.OrderDescending = false;
            this.ExpectIsSet = false;

            this.UsesBuild = false;
        }

        public void SetIterationKeyForValueAndGroupFacets(string iterationKey)
        {
            this.IterationKey = iterationKey;
        }

        public void SetCompoundIterationValueKey(string compoundKey)
        {
            this.CompoundIterationKey = compoundKey;
        }

        public void SetExpect(ScriptBlock expectation)
        {
            this.Expect = expectation;
            this.ExpectIsSet = true;
        }

        public void SetExpectAsStaticKeyValue()
        {
            this.ExpectStaticKey = true;
            this.ExpectIsSet = true;
        }

        public void SetExpectAsCurrentIterationKeyValue()
        {
            this.ExpectCurrentIterationKey = true;
            this.ExpectIsSet = true;
        }

        public void SetExpectAsCurrentChildKeyValue(string childKey)
        {
            this.ExpectGroupChildKey = true;
            this.ChildKey = childKey;
            this.ExpectIsSet = true;
        }

        public void SetExpectAsCompoundKeyValue()
        {
            this.ExpectCompoundValueKey = true;
            this.ExpectIsSet = true;
        }

        public void SetTest(ScriptBlock testBlock)
        {
            this.Test = testBlock;
        }

        public void SetConfigure(ScriptBlock configurationBlock) => this.SetConfigure(configurationBlock, false);
        
        public void SetConfigure(ScriptBlock configurationBlock, bool usesBuild)
        {
            this.Configure = configurationBlock;

            if (usesBuild)
            {
                this.UsesBuild = true;
            }
        }

        public void SetUsesBuild()
        {
            this.UsesBuild = true;
        }

        public void SetStaticKey(string key)
        {
            this.Key = key;
        }

        public void SetStaticKeyValue(object value)
        {
            this.KeyValue = value;
        }

        public void SetRequiresReboot()
        {
            this.RequiresReboot = true;
        }

        public void AddOrderByChildKey(string key)
        {
            this.OrderByChildKey = key;
        }

        public void AddOrderDescending()
        {
            this.OrderDescending = true;
        }

        #region Processing-Details
        public void SetCurrentIteratorDetails(string currentIteratorKey, object currentIteratorValue)
        {
            this.CurrentIteratorKey = currentIteratorKey;
            this.CurrentIteratorKeyValue = currentIteratorValue;
        }

        public void SetCurrentIteratorDetails(string currentIteratorKey, string currentIteratorValue, string currentIteratorChildKey, object currentIteratorChildValue)
        {
            this.CurrentIteratorKey = currentIteratorKey;
            this.CurrentIteratorKeyValue = currentIteratorValue;

            this.CurrentIteratorChildKey = currentIteratorChildKey;
            this.CurrentIteratorChildKeyValue = currentIteratorChildValue;
        }
        #endregion
    }
}