using System;
using System.Management.Automation;

namespace Proviso.Processing
{
    public class ConfigurationResult
    {
        public ValidationResult Validation { get; }
        public bool ConfigurationBypassed { get; private set; }
        public bool ConfigurationSucceeded { get; private set; }
        public bool RecompareSucceeded { get; private set; }
        public object RecompareExpected { get; private set; }
        public object RecompareActual { get; private set; }
        public bool RecompareMatched { get; private set; }
        public ConfigurationError ConfigurationError { get; private set; }

        public ConfigurationResult(ValidationResult validation)
        {
            this.Validation = validation;
            this.ConfigurationBypassed = false;
            this.ConfigurationSucceeded = false;
            this.RecompareSucceeded = false;
            this.RecompareMatched = false;
        }

        public void SetBypassed()
        {
            this.ConfigurationBypassed = true;
            this.ConfigurationSucceeded = true;
        }

        public void SetConfigurationSucceeded()
        {
            this.ConfigurationSucceeded = true;
        }

        public void SetRecompareCompleted(object expected, object actual, bool matched)
        {
            this.RecompareSucceeded = true;

            this.RecompareExpected = expected;
            this.RecompareActual = actual;
            this.RecompareMatched = matched;
        }

        public void AddConfigurationError(ConfigurationError added)
        {
            this.ConfigurationError = added;
        }

        public string GetFacetName()
        {
            return this.Validation.ParentDefinition.Parent.Name;
        }

        public string GetOutcomeSummary()
        {
            // OUTCOME OPTIONS:
            //  a. failure/exception. 
            //  b. previously/already set (i.e., bypassed). 
            //  c. set but recompare failed (i.e., no exceptions but... post-configure value isn't as expected). 
            //  d. set + recompare succeeded - it.., SET.

            if (this.ConfigurationError != null)
                return "ERROR";

            if (this.ConfigurationBypassed)
                return "PRE-SET";  // UNSET? 

            if (this.ConfigurationSucceeded & !this.RecompareMatched)
                return "FAILED";

            return "SET";
        }

        public string GetActualSummary()
        {
            // see OUTCOME OPTIONS in .GetOutcomeSummary(); 
            string output = this.Validation.Actual.ToString().Trim();
            if (string.IsNullOrEmpty(output))
                output = "<EMPTY>";

            if (this.ConfigurationError != null)
                return "Exception: " + this.ConfigurationError.Error.Exception.Message;

            if (this.ConfigurationBypassed)
                return output + " (already set)";

            if (!this.RecompareMatched)
            {
                string actual = "<EMPTY>";
                if (this.RecompareActual != null)
                {
                    actual = this.RecompareActual.ToString().Trim();
                    if (string.IsNullOrEmpty(actual))
                        actual = "<EMPTY>";
                }
                
                return $"Failure. Recompare (post-configure) failed. Expected: {output}, got: {actual}";
            }

            // otherwise, success (i.e., correctly-set) - output the result. 
            return output;
        }
    }
}
