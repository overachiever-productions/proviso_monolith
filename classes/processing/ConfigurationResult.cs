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
        public ErrorRecord ConfigurationError { get; private set; }

        public ConfigurationResult(ValidationResult validation)
        {
            this.Validation = validation;
            this.ConfigurationBypassed = false;
            this.ConfigurationSucceeded = false;
            this.RecompareSucceeded = false;
        }

        public void SetBypassed()
        {
            this.ConfigurationBypassed = true;
        }

        public void SetConfigurationSucceeded()
        {
            this.ConfigurationSucceeded = true;
        }

        public void SetRecompareSucceeded(object expected, object actual, bool matched)
        {
            this.RecompareSucceeded = true;
            this.RecompareExpected = expected;
            this.RecompareActual = actual;
            this.RecompareMatched = matched;
        }

        public void AddConfigurationError(ErrorRecord added)
        {
            this.ConfigurationError = added;
        }
    }
}
