﻿using System;
using System.Collections.Generic;
using System.Management.Automation;

namespace Proviso.Processing
{
    public class ConfigurationResult
    {
        public ValidationResult Validation { get; }
        public bool ConfigurationBypassed { get; private set; }
        public bool ConfigurationFailed => this.ConfigurationErrors.Count > 0;

        public object RecompareExpected { get; private set; }
        public object RecompareActual { get; private set; }
        public bool RecompareMatched { get; private set; }
        public bool RecompareFailed => this.RecompareErrors.Count > 0;

        public List<ConfigurationError> ConfigurationErrors { get; private set; }
        public List<ConfigurationError> RecompareErrors { get; private set; }

        public Guid ProcessingId { get; private set; }

        public ConfigurationResult(ValidationResult validation)
        {
            this.Validation = validation;
            this.ProcessingId = validation.ProcessingId;

            this.ConfigurationBypassed = false;

            this.RecompareMatched = false;

            this.ConfigurationErrors = new List<ConfigurationError>();
            this.RecompareErrors = new List<ConfigurationError>();
        }

        public void SetBypassed()
        {
            this.ConfigurationBypassed = true;
        }

        public void SetRecompareValues(object expected, object actual, bool matched, ErrorRecord actualError, ErrorRecord comparisonError)
        {
            this.RecompareExpected = expected;
            this.RecompareActual = actual;
            this.RecompareMatched = matched;

            if (actualError != null)
            {
                this.RecompareErrors.Add(new ConfigurationError(actualError));
            }

            if (comparisonError != null)
            {
                this.RecompareErrors.Add(new ConfigurationError(comparisonError));
            }
        }

        public void AddConfigurationError(ConfigurationError added)
        {
            this.ConfigurationErrors.Add(added);
        }

        public string GetSurfaceName()
        {
            return this.Validation.ParentFacet.Parent.Name;
        }

        public string GetConfigurationName()
        {
            return $"{this.Validation.ParentFacet.Name}";
        }

        public string GetRecompareSummary()
        {
            // OUTCOME OPTIONS:
            //  a. CONFIG failure/exception. 
            //  b. previously/already set (i.e., bypassed). 
            //  c. recompare failure/error
            //  d. set but recompare failed (i.e., no exceptions but... post-configure value isn't as expected). 
            //  e. just like the above only, parentFacet.RebootRequired = true - so ... output <PENDING> + "Reboot Pending..."
            //  f. set + recompare succeeded - it.., SET.
            if (this.ConfigurationFailed)
            {
                if (this.ConfigurationErrors.Count > 1)
                    return "<ERRORS>";

                return "<ERROR>";
            }

            if (this.ConfigurationBypassed)
                return Formatter.Instance.ToEmptyableString(this.Validation.Actual);

            if (this.RecompareFailed)
            {
                if (this.RecompareErrors.Count > 1)
                    return "<RECOMPARE-ERRORS>";

                return "<RECOMPARE-ERROR>";
            }

            if (!this.RecompareMatched)
            {
                if (this.Validation.ParentFacet.RequiresReboot)
                    return "<PENDING>";
            }

            return Formatter.Instance.ToEmptyableString(this.RecompareActual);
        }

        public string GetOutcomeSummary()
        {
            // OUTCOME OPTIONS:
            //  a. CONFIG failure/exception. 
            //  b. previously/already set (i.e., bypassed). 
            //  c. recompare failure/error
            //  d. set but recompare failed (i.e., no exceptions but... post-configure value isn't as expected). 
            //  e. just like the above only, parentFacet.RebootRequired = true - so ... output <PENDING> + "Reboot Pending..."
            //  f. set + recompare succeeded - it.., SET.

            if (this.ConfigurationFailed)
            {
                if (this.ConfigurationErrors.Count == 1)
                    return "ERROR: " + this.ConfigurationErrors[0].Error.Exception.Message;
                
                return "ERRORS: Encountered " + this.ConfigurationErrors.Count + " Errors during configuration operations.";
            }

            if (this.ConfigurationBypassed)
                return "Already-Matched.";

            if (this.RecompareFailed)
            {
                if (this.RecompareErrors.Count == 1)
                    return "ERROR: " + this.RecompareErrors[0].Error.Exception.Message;

                return "ERRORS: Encountered " + this.RecompareErrors.Count + " Errors during RECOMPARISON testing after [configure] operation.";
            }

            if (!this.RecompareMatched)
            {
                if (this.Validation.ParentFacet.RequiresReboot)
                    return "Reboot Pending...";

                //return "Expected != Actual after Configuration.";
                return "Configuration FAILURE."; // other options might be "Unprovisioned", "Incomplete" and so on... 
            }

            return "Success.";
        }
    }
}
