using System.Management.Automation;

namespace Proviso.Processing
{
    public class ConfigurationError
    {
        public bool IsRecompareError { get; private set; }
        public ErrorRecord Error { get; private set; }

        public ConfigurationError(ErrorRecord error, bool isRecomparisonError)
        {
            this.Error = error;
            this.IsRecompareError = isRecomparisonError;
        }
    }
}
