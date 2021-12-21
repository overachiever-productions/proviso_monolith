using System;
using System.Management.Automation;
using Proviso.Enums;

namespace Proviso.Models
{
    public class Definition
    {
        public Facet Parent { get; set; }
        public DefinitionType DefinitionType { get; private set; }
        public string Description { get; set; }
        public ScriptBlock Expectation { get; private set; }
        public string Key { get; private set; }
        public string ParentKey { get; private set; }  // can be used for BOTH value-definitions and group-definitions.
        public string ChildKey { get; private set; }  // used for GROUP-definitions - i.e., this is the sub-key within a key-block/group.
        public string OrderByChildKey { get; set; }   // this is the child key (for Group-Definitions) to order by - e.g., NetworkAdapters.xxx.ProvisioningPriority would use -OrderByChildKey = "ProvisioningPriority"
        public bool CurrentValueKeyAsExpect { get; private set; }
        public object CurrentKeyValueForValueDefinitions { get; private set; }
        public object CurrentKeyGroupForGroupDefinitions { get; private set; }
        public ScriptBlock Test { get; private set; }
        public ScriptBlock Configure { get; private set; }

        public Definition(Facet parent, string description, DefinitionType type)
        {
            this.Parent = parent;
            this.Description = description;
            this.DefinitionType = type;

            this.CurrentValueKeyAsExpect = false;
        }

        public void AddExpect(ScriptBlock expectation)
        {
            if (this.Key != null)
                throw new InvalidOperationException("A -Key for this Definition has already been provided.");
            
            if(this.CurrentValueKeyAsExpect)
                throw new InvalidOperationException("The -ExpectCurrentKeyValue switch has been provided for this Value-Definition.");

            this.Expectation = expectation;
        }

        public void AddKeyAsExpect(string key)
        {
            if (this.Expectation != null)
                throw new InvalidOperationException("An Expect-block has already been provided.");

            if (this.CurrentValueKeyAsExpect)
                throw new InvalidOperationException("The -ExpectCurrentKeyValue switch has been provided for this Value-Definition.");

            this.Key = key;
        }

        public void AddCurrentKeyValue(object value)
        {
            this.CurrentKeyValueForValueDefinitions = value;
        }

        public void AddOrderByChildKey(string key)
        {
            this.OrderByChildKey = key;
        }

        public void AddCurrentKeyGroup(object value)
        {
            this.CurrentKeyGroupForGroupDefinitions = value;
        }

        public void UseCurrentValueKeyAsExpect(string parentKey)
        {
            if (this.Key != null)
                throw new InvalidOperationException("A -Key for this Definition has already been provided.");

            if (this.Expectation != null)
                throw new InvalidOperationException("An Expect-block has already been provided.");

            this.CurrentValueKeyAsExpect = true;
            this.ParentKey = parentKey;
        }

        public void SetParentKeyForValueDefinition(string parentKey)
        {
            this.ParentKey = parentKey;
        }

        public void SetChildKeyForGroupDefinition(string childKey)
        {
            this.ChildKey = childKey;
        }

        public void AddTest(ScriptBlock testBlock)
        {
            this.Test = testBlock;
        }

        public void AddConfigure(ScriptBlock configurationBlock)
        {
            this.Configure = configurationBlock;
        }
    }
}
