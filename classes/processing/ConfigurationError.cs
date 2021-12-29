using System.Management.Automation;

namespace Proviso.Processing
{
    public class ConfigurationError
    {
        public ErrorRecord Error { get; private set; }

        public ConfigurationError(ErrorRecord error)
        {
            this.Error = error;
        }
    }
}
