using System.Management.Automation;
using Proviso.Enums;

namespace Proviso.Models
{
    public class Facet
    {
        public Surface Parent { get; }
        public string Name { get; }
        public FacetType FacetType { get; }
        public ScriptBlock Test { get; private set; }
        public ScriptBlock Configure { get; private set; }
        public ScriptBlock Expect { get; private set; }

        public string OrderByChildKey { get; set; }
        public bool OrderDescending { get; set; }

        public string Key { get; private set; }

        public bool UsesBuild { get; set; }
        public bool ExpectsKeyValue { get; private set; }
        public bool ExpectCurrentIterationKey { get; private set; }
        public bool ExpectIsSet { get; private set; }

        public bool RequiresReboot { get; set; }

        // dynamic/run-time values: 
        private string _currentInstanceName;

        public string CurrentSqlInstanceName
        {
            get
            {
                if (string.IsNullOrWhiteSpace(this._currentInstanceName))
                    return "MSSQLSERVER";

                return this._currentInstanceName;
            }
            set
            {
                this._currentInstanceName = value;
            }
        }

        public string CurrentObjectName { get; set; }
        public string CurrentKey { get; set; }
        public object CurrentKeyValue { get; set; }

        public Facet(Surface parent, string name, FacetType type, string facetKey)
        {
            this.Parent = parent;
            this.Name = name;
            this.FacetType = type;
            this.Key = facetKey;

            this.RequiresReboot = false;
            this.OrderDescending = false;
            this.ExpectIsSet = false;

            this.UsesBuild = false;
        }

        public void SetExpect(ScriptBlock expectation)
        {
            this.Expect = expectation;
            this.ExpectIsSet = true;
        }

        public void SetExpectForKeyValue()
        {
            this.ExpectsKeyValue = true;
            this.ExpectIsSet = true;
        }

        public void SetExpectForIteratorValue()
        {
            this.ExpectCurrentIterationKey = true;
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
    }
}
