using System;
using System.Collections;
using System.Management.Automation;

namespace Proviso.Models
{
    public class Tester
    {
        private PSObject _config;

        public Tester(PSObject config)
        {
            this._config = config;
        }

        public string GetEverything()
        {
            return this._config.ToString();
        }

        public object GetStuffByKey(string key)
        {
            // REFACTOR: this code is just ... brute-force/vile. 
            string[] keys = key.Split('.');

            switch (keys.Length)
            {
                case 1:
                    return this._config.Properties[key].Value;
                case 2:
                    if (this._config.Properties[keys[0]].Value is Hashtable primary)
                        return primary[keys[1]];
                    break;
                case 3:
                    if (this._config.Properties[keys[0]].Value is Hashtable primary3)
                    {
                        if (primary3[keys[1]] is Hashtable secondary)
                            return secondary[keys[2]];
                    }
                    break;
                case 4:
                    if (this._config.Properties[keys[0]].Value is Hashtable primary4)
                    {
                        if (primary4[keys[1]] is Hashtable secondary4)
                        {
                            if (secondary4[keys[2]] is Hashtable tertiary)
                                return tertiary[keys[3]];
                        }
                    }
                    break;
                case 5:
                    if (this._config.Properties[keys[0]].Value is Hashtable primary5)
                    {
                        if (primary5[keys[1]] is Hashtable secondary5)
                        {
                            if (secondary5[keys[2]] is Hashtable tertiary5)
                            {
                                if (tertiary5[keys[3]] is Hashtable quaternary)
                                    return quaternary[keys[5]];
                            }
                                
                        }
                    }
                    break;
                default:
                    // arguably, this might be a length of 0? 
                    throw new ArgumentException("Invalid Key. Too many key segments defined.");
            }

            throw new ArgumentException($"Invalid Key. The key [{key}] did not yield any matches.");
        }
    }
}
